require 'descendants_tracker'

module TrepScore
  module Services
    class Service
      extend DescendantsTracker

      class << self
        ######################
        # SERVICE SCHEMA DSL #
        ######################

        # Gets the current schema for the data attributes that this Service
        # expects.  This schema is used to generate the service settings
        # interface.  The attribute types loosely to HTML input elements. Each
        # also accepts an options hash, used to denote optional vs required elements.
        #
        # Example:
        #
        #   class FooService < Service
        #     string :token, required: true
        #     string :title, required: false
        #   end
        #
        #   FooService.schema
        #   # => [[:string, :token, :required], [:string, :token, :optional], ]
        #
        # Returns an Array of tuples:
        #  [Symbol attribute type, Symbol attribute name, Symbol attribute required]
        def schema
          @schema ||= []
        end

        # Public: Adds the given attributes as String attributes in the Service's
        # schema.
        #
        # Example:
        #
        #   class FooService < Service
        #     string :token
        #   end
        #
        #   FooService.schema
        #   # => [[:string, :token, :required]]
        #
        # *attrs - Array of Symbol attribute names.
        #
        # Returns nothing.
        def string(*attrs)
          add_to_schema :string, attrs
        end

        # Public: Adds the given attributes as Password attributes in the Service's
        # schema.
        #
        # Example:
        #
        #   class FooService < Service
        #     password :token
        #   end
        #
        #   FooService.schema
        #   # => [[:password, :token, :required]]
        #
        # *attrs - Array of Symbol attribute names.
        #
        # Returns nothing.
        def password(*attrs)
          add_to_schema :password, attrs
        end

        # Public: Adds the given attributes as Boolean attributes in the Service's
        # schema.
        #
        # Example:
        #
        #   class FooService < Service
        #     boolean :digest
        #   end
        #
        #   FooService.schema
        #   # => [[:boolean, :digest, :required]]
        #
        # *attrs - Array of Symbol attribute names.
        #
        # Returns nothing.
        def boolean(*attrs)
          add_to_schema :boolean, attrs
        end

        # Public: Add required schema attributes. This helper is available to help provide
        # clarity to service classes. All attributes are required by default unless flagged
        # as :optional with this helper's counterpart: optional {}
        #
        # Example:
        #
        #   class FooService < Service
        #     required do
        #       string :token
        #     end
        #   end
        #
        #   FooService.schema
        #   # => [[:string, :token, :required]]
        def required(&blk)
          @schema_flag = :required
          instance_eval &blk
          @schema_flag = nil
        end

        # Public: Add optional schema attributes. Attributes defined within the block are
        # flagged as optional and will be displayed as such in the settings interface.
        #
        # Example:
        #
        #   class FooService < Service
        #     optional do
        #       string :nickname
        #     end
        #   end
        #
        #   FooService.schema
        #   # => [[:string, :nickname, :optional]]
        def optional(&blk)
          @schema_flag = :optional
          instance_eval &blk
          @schema_flag = nil
        end

        # Adds the given attributes to the Service's data schema. Refers to @schema_flag
        # to determine the requireability of the attribute
        #
        # type  - A Symbol specifying the type: :string, :password, :boolean.
        # attrs - Array of Symbol attribute names.
        #
        # Returns nothing.
        def add_to_schema(type, attrs)
          attrs.each do |attr|
            schema << [type, attr.to_sym, (@schema_flag || :required)]
          end
        end

        ###################
        # CONTRIBUTOR DSL #
        ###################

        # Track the service supporters
        #
        # Returns an Array of Contributors
        def supporters
          @supporters ||= []
        end

        # Track the service maintainers
        #
        # Returns an Array of Contributors
        def maintainers
          @maintainers ||= []
        end

        # Defines the maintainers for the service. Maintainers
        # are the ones who actively contribute to the codebase and
        # receive credit when credit is due.
        #
        # Example:
        #
        #   class FooService < Service
        #     maintained_by :github => 'ryanfaerman'
        #   end
        #
        # Returns an Array of Contributer Objects.
        def maintained_by(values)
          values.each do |contributor_type, value|
            maintainers.push(*Contributor.create(contributor_type, value))
          end
        end

        ########################
        # GENERAL/METADATA DSL #
        ########################

        # Gets/sets the official title of this Service.  This is used in any
        # user-facing documentation regarding the Service.
        #
        # Returns a String.
        def title(value = nil)
          if value
            @title = value
          else
            @title ||= begin
              hook = name.dup
              hook.sub! /.*:/, ''
              hook
            end
          end
        end

        # Gets/sets the name that identifies this Service type.  This is a
        # short string that is used to uniquely identify the service internally.
        #
        # Returns a String.
        def hook_name(value = nil)
          if value
            @hook_name = value
          else
            @hook_name ||= begin
              hook = name.dup
              hook.downcase!
              hook.sub! /.*:/, ''
              hook
            end
          end
        end

        # Gets/Sets the url that a user uses access the service. This is
        # the public url of the service.
        def url(value = nil)
          if value
            @url = value
          else
            @url
          end
        end

        # Gets/Sets the category of the service. Categories are used to sort the
        # services within the user interface. See the wiki for valid categories.
        def category(value = nil)
          if value
            @category = value
          else
            @category
          end
        end

        # Gets/Sets the URL to the logo used by the service.
        def logo_url(value = nil)
          if value
            @logo_url = value
          else
            @logo_url
          end
        end

        # Gets the related documentation from the /docs folder
        #
        # Returns the documentation or an empty string
        def documentation
          file = name.dup
          file.downcase!
          file.sub! /.*:/, ''
          doc_file = File.expand_path("../../../../doc/#{file}", __FILE__)
          File.exists?(doc_file) ? File.read(doc_file) : ""
        end

        # Define the oauth provider and a filter for the OmniAuth response. This
        # should map to a provider defined for OmniAuth, the oauth library we use
        # for authenticating against third party services. Include the integration
        # library for OmniAuth in the Gemfile.
        #
        # The filter block receives two arguments, the response hash and an `extra`
        # hash with any other POST/GET parameters.
        #
        # Example:
        #
        #   class FooService < Service
        #     oauth(provider: :github) do |response, extra|
        #       {
        #          realm_id: extra['realmId'],
        #          credentials: response['credentials']
        #       }
        #     end
        #   end
        #
        def oauth(provider:nil, &blk)
          @oauth ||= {
            provider: provider,
            filter: blk
          }
        end

        # Helper used to determine if the service is using OAuth.
        def oauth?
          !@oauth.nil?
        end

        #############################
        # TREPSCORE INTEGRATION API #
        #############################

        # Confirm that the data meets the requirements of the schema and
        # raise a configuration error if it does not.
        def validate(data = {})
          errors = {}

          make_hash_indifferent(data)

          schema.each do |_, attribute, flag|
            next if flag == :optional

            if data[attribute.to_s].to_s == ''
              errors[attribute] = [:required, 'cannot be blank']
            end
          end

          errors
        end

        def validate!(data = {})
          errors = validate(data)

          if errors.any?
            messages = []
            errors.each do |field, (_, message)|
              messages << [field, message].join(' ')
            end
            raise ConfigurationError, messages.join(', ')
          end
        end

        # Test that the data is acceptable to the external service and
        # raise a configuration error if it is not.
        def test(data = {})
          make_hash_indifferent(data)
          validate!(data)
          new(data).test
        end

        # Call the service and collect the data points.
        #
        # period  - the date range or ranges to collect information for
        # data    - a hash of stored settings, as defined by the schema
        #
        # Returns a hash in the form of {Range => Metrics Hash}.
        def call(period:, data: {})
          results = {}

          make_hash_indifferent(data)
          validate!(data)
          instance = new(data)

          period = [period] unless period.is_a? Array
          period.each do |p|
            results[p] = instance.call(p)
          end

          results
        end

        private
          INDIFFERENT_PROC = proc do |h, k|
            case k
            when String then h[k.to_sym] if h.key?(k.to_sym)
            when Symbol then h[k.to_s] if h.key?(k.to_s)
            end
          end

          def make_hash_indifferent(hash)
            hash.default_proc = INDIFFERENT_PROC
          end
      end

      attr_reader :data

      # Basic initializer provided to make life easier. All data needed
      # from OAuth or the Schema is passed through the `data` hash.
      def initialize(data)
        @data = data

        validate
      end

      # Interface method that every service MUST implement. This should return
      # a hash of pertinent data for the given time period
      # rubocop:disable Lint/UnusedMethodArgument
      def call(period)
        raise NotImplementedError.new "#{self.class.name} is not callable"
      end

      # An optional interface method. This is executed when setting up the service,
      # and provides a way to check that the settings are acceptable to the
      # external service provider. Raise a configuration error or other error type
      # to indicate that the settings data is unacceptable.
      def test
        warn "#{self.class.name} is not testable"
      end

      # An optional interface method. This is executed upon instantiation and
      # provides a chance to validate the inputs for something other than presence.
      # Raise a configuration error to indicate that the settigns data is unacceptable.
      def validate
        # optional
      end

      # Public: Raises a configuration error inside a service, and halts further
      # processing.
      #
      # Raises a Service::ConfigurationError.
      def raise_config_error(msg = "Invalid configuration")
        raise ConfigurationError, msg
      end

      # Public: Raises a not ready signal inside a service, and halts further
      # processing.
      #
      # delay - integer of delay in seconds
      #
      # Raises a Service::NotReadySignal .
      def signal_not_ready(delay = nil)
        raise NotReadySignal.new(delay)
      end
    end
  end
end
