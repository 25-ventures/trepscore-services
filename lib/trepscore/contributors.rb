module TrepScore
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
      { :type => self.class.contributor_type, key => value }
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

  class WebContributor < Contributor
    def self.contributor_type
      :web
    end

    def to_hash
      to_contributor_hash(:url)
    end
  end
end
