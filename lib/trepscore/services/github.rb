module TrepScore
  module Services
    class GitHub < Service
      # TODO: This is not used
      class StatsNotReady < StandardError; end

      category :developer_tools

      required do
        string :id
        string :repo
        string :token
      end

      url 'http://github.com'
      # url_logo 'https://assets-cdn.github.com/images/modules/logos_page/GitHub-Logo.png'

      maintained_by github: 'federomero',
                    email:  'hi@federomero.uy',
                    web:    'http://federomero.uy'

      oauth(provider: :github, scope: 'user,repo') do |response, _|
        {
          token: response['credentials']['token'],
          id: response['uid'],
        }
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
          raise TrepScore::ConfigurationError.new('Repo not found', e)
        end
      end
    end
  end
end

require 'trepscore/services/github/client'
