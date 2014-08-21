# Represents a single associated third party service. Each service
# implements the `call` method returning the data from the service.
class Service
  class Contributor < Struct.new(:value)
    def self.contributor_types
      @contributor_types ||= []
    end

    def self.inherited(contributor_type)
      contributor_types << contributor_type
      super
    end

    def self.create(type, keys)
      klass = contributor_types.detect { |struct| struct.contributor_type == type }
      if klass
        Array(keys).map do |key|
          klass.new(key)
        end
      else
        raise ArgumentError, "Invalid Contributor type #{type.inspect}"
      end
    end

    def to_contributor_hash(key)
      {:type => self.class.contributor_type, key => value}
    end
  end

  class WebContributor < Contributor
    def self.contributor_type
      :web
    end

    def to_hash
      to_contributor_hash(:url)
    end
  end

  class EmailContributor < Contributor
    def self.contributor_type
      :email
    end

    def to_hash
      to_contributor_hash(:address)
    end
  end

  class GitHubContributor < Contributor
    def self.contributor_type
      :github
    end

    def to_hash
      to_contributor_hash(:login)
    end
  end

  class << self

    # Load all available services
    def load_services
      path = File.expand_path("../services/*.rb", __FILE__)
      Dir[path].each { |lib| require(lib) }
    end

    # Tracks the defined services.
    #
    # Returns an Array of Service Classes
    def services
      @services ||= []
    end

    # Gets the current schema for the data attributes that this Service
    # expects.  This schema is used to generate the service settings
    # interface.  The attribute types loosely to HTML input elements.
    #
    # Example:
    #
    #   class FooService < Service
    #     string :token
    #   end
    #
    #   FooService.schema
    #   # => [[:string, :token]]
    #
    # Returns an Array of [Symbol attribute type, Symbol attribute name] tuples.
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
    #   # => [[:string, :token]]
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
    #   # => [[:password, :token]]
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
    #   # => [[:boolean, :digest]]
    #
    # *attrs - Array of Symbol attribute names.
    #
    # Returns nothing.
    def boolean(*attrs)
      add_to_schema :boolean, attrs
    end

    # Adds the given attributes to the Service's data schema.
    #
    # type  - A Symbol specifying the type: :string, :password, :boolean.
    # attrs - Array of Symbol attribute names.
    #
    # Returns nothing.
    def add_to_schema(type, attrs)
      attrs.each do |attr|
        schema << [type, attr.to_sym]
      end
    end

    # Public: get a list of attributes that are approved for logging.  Don't
    # add things like tokens or passwords here.
    #
    # Returns an Array of String attribute names.
    def white_listed
      @white_listed ||= []
    end

    # Adds the given attributes to the whitelist.
    def white_list(*attrs)
      attrs.each do |attr|
        white_listed << attr.to_s
      end
    end

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

    # Defines the supporters for the service.
    #
    # Example:
    #
    #   class FooService < Service
    #     supported_by web:   'http://my-service.com/support',
    #                  email: 'support@my-service.com'
    #   end
    #
    # Returns an Array of Contributer Objects.
    def supported_by(values)
      values.each do |contributor_type, value|
        supporters.push(*Contributor.create(contributor_type, value))
      end
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

    # Automatically registers the service as it is Required.
    #
    # Returns nothing
    def inherited(svc)
      Service.services << svc
      super
    end

    # Instantiates the service, passes the data, and calls it.
    #
    # Returns a hash of data to be stored.
    def call(data: {})
      new(data: data).call
    end

    # Gets the related documentation from the /docs folder
    #
    # Returns the documentation or an empty string
    def documentation
      file = name.dup
      file.downcase!
      file.sub! /.*:/, ''
      doc_file = File.expand_path("../../doc/#{file}", __FILE__)
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

  end

  attr_reader :data

  # Basic initializer provided to make life easier. All data needed
  # from OAuth or the Schema is passed through the `data` hash.
  def initialize(data: {})
    @data = data || {}
  end

  # Interface method that every service MUST implement. This should return
  # a hash of pertinent data.
  def call
    msg = "#{self.class.name} is not callable"
    raise NotImplementedError.new msg
  end

  # Raised when an unexpected error occurs during service execution.
  class Error < StandardError
    attr_reader :original_exception
    def initialize(message, original_exception=nil)
      original_exception = message if message.kind_of?(Exception)
      @original_exception = original_exception
      super(message)
    end
  end

  # Raised when a service hook fails due to bad configuration. Services that
  # fail with this exception may be automatically disabled.
  class ConfigurationError < Error; end

  # Public: Raises a configuration error inside a service, and halts further
  # processing.
  #
  # Raises a Service::ConfigurationError.
  def raise_config_error(msg = "Invalid configuration")
    raise ConfigurationError, msg
  end

end
