require 'trepscore/services/service'

module TrepScore
  module Services
    VERSION = '0.0.2'

    class << self
      # Load all available services
      def load
        path = File.expand_path("../services/*.rb", __FILE__)
        Dir[path].each { |lib| require(lib) }
      end

      # Tracks the defined services.
      #
      # Returns an Array of Service Classes
      def registry
        Service.descendants
      end
    end
  end
end
