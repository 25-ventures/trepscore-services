require 'faraday'
require 'faraday_middleware'

module Pipedrive
  class Base

    include Enumerable

    def initialize(options = {})
      @options = options
      authenticate
    end

    def authenticate(token = @options[:api_token])
      default_params.merge! api_token: token
    end

    def get(options = {})
      return to_enum(__callee__, options) unless block_given?

      response = _get_resource(options)
      if response.success?
        data = [(response.body['data'] || [])].flatten
        data.each do |item|
          yield OpenStruct.new item
        end
        # binding.pry
        
        if next_start(response)
          options[:params] = (options[:params]||{}).merge({start: next_start(response)})
          # binding.pry
          send(__callee__, options) do |data|
            yield data
          end
        end
      end

    end
    alias_method :each, :get

    
    def metrics
      metrics = {total: all.count}
      
      get.each do |item|
        key = metric_key(item)
        break if key.nil?

        metrics[key] ||= 0
        metrics[key] += 1
      end

      metrics
    end

    def metric_key(item)
      (item.try(:type) || item.try(:status)).try(:to_sym)
    end

    def all(options = {})
      data = []
      each(options).collect {|i| data << i}
      data
    end

    def prepare_options(options = {})
      options
    end

    def protocol
      'http://'
    end

    def base_uri
      protocol + 'api.pipedrive.com/v1'
    end

    def resource_path
      # The resource path should match the camelCased class name with the
      # first letter downcased.  Pipedrive API is sensitive to capitalisation
      klass = self.class.name.split('::').last
      klass[0] = klass[0].chr.downcase
      klass
    end

    def resource(klass_name)
      klass_name = klass_name.to_s.split('_').map(&:capitalize).join
      _klasses[klass_name] ||= begin
        klass = Object.const_get "::Pipedrive::#{klass_name}"
        klass.new @options
      end
    end

    def [](id)
      path = [resource_path, id.to_s].join '/'
      get(resource_path: path).first
    end

    private
      def _get_resource(options = {})
        params = default_params.merge (options.delete(:params) ||  {})
        
        response = connection.get do |req|
          req.url (options.delete(:resource_path) || resource_path)
          req.headers = ::Pipedrive::HEADERS
          req.params.merge! params
        end
      end

      def _klasses
        @_klasses ||= {}
      end

      def next_start(response)
        additional_data = response.body['additional_data']
        if !additional_data.nil? && additional_data['pagination'] && additional_data['pagination']['more_items_in_collection']
          additional_data['pagination']['next_start']
        end
      end

      def default_params
        @default_params ||= {}
      end

      def connection
        @connection ||= ::Faraday.new(url: base_uri) do |conn|
          conn.request :url_encoded
          conn.adapter ::Faraday.default_adapter

          conn.response :json, content_type: /\bjson$/
          conn.response :xml,  content_type: /\bxml$/
        end
      end
  end
end