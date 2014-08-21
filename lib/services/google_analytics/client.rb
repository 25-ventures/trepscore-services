class GoogleAnalytics::Client < GoogleAnalytics::Base
  
  undef resource_path

  def metrics
    
    metrics = {}
    
    %i{user}.each do |source|
      metrics[source] = send(source).metrics
    end
    metrics
  end
  
  def method_missing(name, *args, &block)
    begin 
      resource(name)
    rescue NameError
      raise NoMethodError, "undefined method '#{name}' for #{self}"
    end
  end
end
