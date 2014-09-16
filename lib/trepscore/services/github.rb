module Github
  autoload :Client, 'trepscore/services/github/client'

  # Custom exceptions
  class StatsNotReady < StandardError; end
end

module TrepScore
  module Services
    class Github < Service
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

      oauth(provider: :github) do |response, _|
        {
          token: response['credentials']['token'],
          id: response['uid'],
        }
      end

      def call(period)
        client = ::Github::Client.new(
                                        period: period,
                                        token: data['token'],
                                        id: data['id'],
                                        repo: data['repo'],
                                      )
        begin
          client.metrics
        rescue ::Github::StatsNotReady
          signal_not_ready(5)
        rescue Octokit::NotFound => e
          raise TrepScore::ConfigurationError.new('Repo not found', e)
        end
      end
    end
  end
end
