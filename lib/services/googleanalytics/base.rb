require 'garb'
require 'json'

module Googleanalytics
  
  class Exits
    extend Garb::Model
    metrics :visits, :bounceRate,:goalConversionRateAll,:users,:organicSearches
    dimensions :visitorType,:visitLength
  end
  
  class Base
        
    include Enumerable

    def initialize(options = {})
      @options = options
      
    end

    def get(options = {})
      begin
        Garb::Session.login(@options[:client_id],  @options[:client_secret] ,:secure => false)
        profile = Garb::Management::Profile.all.detect {|p| p.web_property_id == @options[:webId]}
        
          totalVisit = 0
          uniqueVisit = 0
          bounceRate = 0
          visitLength = 0
          conversionRate = 0
          
          report = Exits.results(profile)
          count = report.size
          report.each do |rep|
            totalVisit += rep.visits.to_i
            uniqueVisit += rep.users.to_i 
            bounceRate += rep.bounce_rate.to_f
            visitLength += rep.visit_length.to_f
            conversionRate += rep.goal_conversion_rate_all.to_f
          end
        bounceRate = bounceRate / count
        visitLength = visitLength / (count * 60)
        conversionRate = conversionRate/count
        
      rescue
        puts "Not Authenticated"
      end
      jsonlist = { :totalVisit => totalVisit, :uniqueVisit => uniqueVisit,:bounceRate =>bounceRate , :visitLength => visitLength, :conversionRate => conversionRate}
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
        klass = Object.const_get "::Googleanalytics::#{klass_name}"
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
