module Pipedrive
  HEADERS = {
    "User-Agent"    => "Ruby.Pipedrive.Api",
    "Accept"        => "application/json",
    "Content-Type"  => "application/x-www-form-urlencoded"
  }

  autoload :Activities,     'pipedrive/activities'
  autoload :ActivityTypes,  'pipedrive/activity_types'
  autoload :Client,         'pipedrive/client'
  autoload :Base,           'pipedrive/base'
  autoload :Deals,          'pipedrive/deals'
  autoload :Emails,         'pipedrive/emails'
  autoload :Files,          'pipedrive/files'
  autoload :Filters,        'pipedrive/filters'
  autoload :Goals,          'pipedrive/goals'
  autoload :Notes,          'pipedrive/notes'
  autoload :Organizations,  'pipedrive/organizations'
  autoload :Persons,        'pipedrive/persons'
  autoload :Pipelines,      'pipedrive/pipelines'
  autoload :Products,       'pipedrive/products'
  autoload :Roles,          'pipedrive/roles'
  autoload :Stages,         'pipedrive/stages'
  autoload :Users,          'pipedrive/users'
end

module TrepScore
  module Services
    class Pipedrive < Service
      category :crm

      required do
        string :token
      end

      def call(*)
        client = ::Pipedrive::Client.new(api_token: data['token'])
        client.metrics
      end
    end
  end
end
