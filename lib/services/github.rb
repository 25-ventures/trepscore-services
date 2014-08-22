module Github
  # HEADERS = {
  #   "User-Agent"    => "Ruby.Github.Api",
  #   "Accept"        => "application/json",
  #   "Content-Type"  => "application/x-www-form-urlencoded"
  # }

  autoload :Client,         'github/client'
end

class Service::Github < Service
  category :developer_tools

  string :token
  string :repo
  string :id

  url 'http://github.com'
  # url_logo 'https://assets-cdn.github.com/images/modules/logos_page/GitHub-Logo.png'

  maintained_by github: 'federomero',
                email:  'hi@federomero.uy',
                web:    'http://federomero.uy'


  oauth(provider: :github) do |response, _|
    {
      token: response['credentials']['token'],
      id: response["uid"],
    }
  end

  def call
    %w(id token repo).each do |field|
      raise_config_error "Missing '#{field}'" if data[field.to_sym].to_s == ''
    end

    client = ::Github::Client.new(token: data[:token], id: data[:id], repo: data[:repo])
    client.metrics
  end
end
