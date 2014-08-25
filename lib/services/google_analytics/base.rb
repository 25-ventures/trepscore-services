require 'garb'

module GoogleAnalytics
  
  class Exits
    extend Garb::Model
      metrics :pageviews,:bounceRate,:avgSessionDuration,:sessions,:users,:transactions,:visits    
  end
  
  class Base
        
    def initialize(options = {})
      @options = options
      authenticate
    end
    
    def authenticate(client_id = @options[:client_id],client_secret = @options[:client_secret])
      Garb::Session.login(client_id, client_secret, :secure => false)
    end
    
    def get_data(options = {})      
      profile = Garb::Management::Profile.all.detect {|p| p.web_property_id == @options[:web_id]}        
    end
    
    def report
      Exits.results(get_data)
    end
    
    def get
      total_visit = 0
      unique_visit = 0
      bounce_rate = 0
      visit_length = 0
      conversion_rate = 0
      transactions = 0
            
      report.each do |repo|
          total_visit = repo.visits.to_i
          unique_visit = repo.users
          bounce_rate = repo.bounce_rate
          visit_length = repo.avg_session_duration.to_i
          transactions = repo.transactions.to_i                              
      end
      conversion_rate = ( transactions / total_visit) * 100
      data_list = { :total_visit => total_visit, :unique_visit => unique_visit,:bounce_rate =>bounce_rate , :visit_length => visit_length/60, :conversion_rate => conversion_rate}
    end
   
    def metrics
      get
    end
    
    def resource_path
      klass = self.class.name.split('::').last
      klass[0] = klass[0].chr.downcase
      klass
    end

    def resource(klass_name)
      klass_name = klass_name.to_s.split('_').map(&:capitalize).join
      _klasses[klass_name] ||= begin
        klass = Object.const_get "::GoogleAnalytics::#{klass_name}"
        klass.new @options
      end
    end

    def [](id)
      path = [resource_path, id.to_s].join '/'
      get(resource_path: path).first
    end
    
    private
      def _klasses
        @_klasses ||= {}
      end
  end
end
