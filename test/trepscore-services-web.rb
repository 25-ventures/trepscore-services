require 'sinatra'
require "sinatra/reloader"
require "sinatra/namespace"
require "sinatra/config_file"
require "sinatra/multi_route"
require 'haml'
require 'redcarpet'
require 'omniauth'

require 'rubygems'
require 'bundler/setup'
require 'pry'

require 'trepscore'

TrepScore::Services.load

class TrepScoreServicesWeb < Sinatra::Base
  register Sinatra::Reloader
  also_reload './lib/**/*.rb'

  register Sinatra::Namespace
  register Sinatra::ConfigFile
  register Sinatra::MultiRoute

  set :public_folder, File.dirname(__FILE__) + '/assets'
  enable :sessions
  config_file 'config.yml'

  use OmniAuth::Builder do
    use OmniAuth::Strategies::Developer
  end

  use Rack::MethodOverride

  OAUTH_SERVICES ||= {}

  ::TrepScore::Services.registry.each do |service|
    if service.oauth?
      oauth = service.oauth
      provider = oauth[:provider].to_sym

      key_name = "#{provider}_key"
      secret_name = "#{provider}_secret"
      key = settings.send(key_name) if settings.respond_to? key_name
      secret = settings.send(secret_name) if settings.respond_to? secret_name

      if !key.nil? && !secret.nil?
        ENV[key_name.upcase] = key
        ENV[secret_name.upcase] = secret

        use OmniAuth::Builder do
          provider provider, key, secret, scope: oauth[:scope]
        end

        OAUTH_SERVICES[provider] = service
      end
    end
  end

  get '/' do
    @services = ::TrepScore::Services.registry
    haml :services
  end

  route :get, :post, '/auth/:provider/callback' do
    service = OAUTH_SERVICES[params[:provider].to_sym]

    session[(service.hook_name + '_oauth')] = service.oauth[:filter].call(request.env['omniauth.auth'], params)
    redirect "/service/#{service.hook_name}"
  end

  get '/auth/failure' do
    @strategy = params[:strategy]
    @reason = params[:message]
    haml :oauth_failed
  end

  namespace '/service/:hook_name' do
    before do
      @service = ::TrepScore::Services.registry.select {|s| s.hook_name.to_s == params[:hook_name]}.first
      @oauth_env_ready = OAUTH_SERVICES.has_key?(@service.oauth[:provider])

      @data = session[@service.hook_name] || {}
      @oauth_data = session[@service.hook_name + '_oauth'] || {}

      @integration_data = @data.merge(@oauth_data)

      @last_response = session[@service.hook_name + '_last_response'] || {}
    end

    get do
      @maintainers = @service.maintainers.map(&:to_hash).map(&:values)

      haml :service
    end

    post do
      fields = @service.schema.map {|attribute| attribute[1]}.map(&:to_s)
      session[@service.hook_name] = params.select {|k| params[k] if fields.include?(k)}

      redirect "/service/#{@service.hook_name}"
    end

    delete do
      if params.has_key?('oauth-purge')
       session.delete(@service.hook_name + '_oauth')
       redirect "/service/#{@service.hook_name}"
     end
    end

    post '/call' do
      @range_start = Date.parse(params['range-start'])
      @range_end = Date.parse(params['range-end'])

      @period = (@range_start..@range_end)

      begin
        response = @service.new(@integration_data).call(@period)
        session[@service.hook_name + '_last_response'] = response

        redirect "/service/#{@service.hook_name}"
      rescue ::TrepScore::ConfigurationError => e
        @reason = e.to_s
        haml :service_failed
      end

    end
  end
end
