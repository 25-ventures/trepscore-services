module Googleanalytics
  
  autoload :Base, 'googleanalytics/base'
  autoload :Client, 'googleanalytics/client'
  autoload :User, 'googleanalytics/user'
  
end
  
class Service::Googleanalytics < Service
  string :client_id, :client_secret, :webId
  category :analytics
  
  def call
     client = ::Googleanalytics::Client.new(client_id: client_id, client_secret: client_secret, webId: webId)
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
  
  def webId
      raise_config_error "Missing 'webId'" if data[:webId].to_s ==''
      data[:webId]
    end
end