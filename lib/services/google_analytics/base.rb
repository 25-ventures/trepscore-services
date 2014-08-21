require 'garb'

module GoogleAnalytics
  
  class Exits
    extend Garb::Model
    metrics :sessions, :bounce_rate,:goal_conversion_rate_all,:users,:organic_searches
    dimensions :visitor_type,:visit_length,:day
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
      count = report.size
      report.each do |rep|
        total_visit += rep.visits.to_i
        unique_visit += rep.users.to_i 
        bounce_rate += rep.bounce_rate.to_f
        visit_length += rep.visit_length.to_f
        conversion_rate += rep.goal_conversion_rate_all.to_f
      end
      bounce_rate = bounce_rate / count
      visit_length = visit_length / (count * 60)
      conversion_rate = conversion_rate/count
      data_list = { :total_visit => total_visit, :unique_visit => unique_visit,:bounce_rate =>bounce_rate , :visit_length => visit_length, :conversion_rate => conversion_rate}
      data_list      
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
