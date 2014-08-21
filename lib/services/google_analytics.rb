module GoogleAnalytics
  
  autoload :Base, 'google_analytics/base'
  autoload :Client, 'google_analytics/client'
  autoload :Data, 'google_analytics/data'
  
end
  
class Service::GoogleAnalytics < Service
  string :client_id, :client_secret, :web_id
  category :analytics
  
  def call
     client = ::GoogleAnalytics::Client.new(client_id: client_id, client_secret: client_secret, web_id: web_id)
     client.metrics      
  end

  def client_id
    raise_config_error "Missing 'client_id'" if data[:client_id].to_s ==''
    data[:client_id]
  end

  def client_secret
    raise_config_error "Missing 'client secret'" if data[:client_secret].to_s==''
    data[:client_secret]
  end
  
  def web_id
      raise_config_error "Missing 'web_id'" if data[:web_id].to_s ==''
      data[:web_id]
    end
end