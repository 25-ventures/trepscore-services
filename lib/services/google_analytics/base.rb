require 'garb'

module GoogleAnalytics
  
  class Exits
    extend Garb::Model
    metrics :visits, :bounceRate,:goalConversionRateAll,:users,:organicSearches
    dimensions :visitorType,:visitLength
  end
  
  class Base
        
    def initialize(options = {})
      @options = options
      
    end

    def get(options = {})
      Garb::Session.login(@options[:client_id],  @options[:client_secret] ,:secure => false)
      profile = Garb::Management::Profile.all.detect {|p| p.web_property_id == @options[:web_id]}
  
      total_visit = 0
      unique_visit = 0
      bounce_rate = 0
      visit_length = 0
      conversion_rate = 0
      
      report = Exits.results(profile)
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
      jsonlist = { :total_visit => total_visit, :unique_visit => unique_visit,:bounce_rate =>bounce_rate , :visit_length => visit_length, :conversion_rate => conversion_rate}
    
      jsonlist      
    end
    alias_method :each, :get

    def metrics
      metrics =  get
      metrics
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
