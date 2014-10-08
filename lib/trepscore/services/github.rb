require 'omniauth-github'

module TrepScore
  module Services
    class GitHub < Service
      # This is not used yet, but will be needed for any files stats (lines added, etc.)
      class StatsNotReady < StandardError; end

      category :developer_tools

      required do
        string :repo
      end

      url 'http://github.com'
      logo_url 'https://assets-cdn.github.com/images/modules/logos_page/GitHub-Mark.png'

      maintained_by github: 'federomero',
                    email:  'hi@federomero.uy',
                    web:    'http://federomero.uy'

      oauth(:github) do |config|
        config.scope  = 'user,repo'
        config.filter = proc do |response, params|
          {
            token: response['credentials']['token'],
            id: response['uid'],
          }
        end
      end

      def call(period)
        client = Client.new(
          period: period,
          token: data['token'],
          id: data['id'],
          repo: data['repo'],
        )
        begin
          client.metrics
        rescue StatsNotReady
          signal_not_ready(5)
        rescue Octokit::NotFound => e
          raise TrepScore::ConfigurationError.new("Repo '#{client.repo}' was not found", e)
        end
      end
    end
  end
end

# Require this last because it depends on the above being defined
require 'trepscore/services/github/client'
