require 'omniauth-google-oauth2'

module TrepScore
  module Services
    class GoogleAnalytics < Service
      category :analytics

      required do
        string :account
        string :profile
      end

      url 'http://www.google.com/analytics/'

      maintained_by github: 'federomero',
                    email:  'hi@federomero.uy',
                    web:    'http://federomero.uy'

      oauth(:google_oauth2) do |config|
        config.scope   = 'email,analytics.readonly'
        config.options = { prompt: 'consent' }  # Needed so we get a refresh_token
        config.filter  = proc do |response, params|
          {
            token: response['credentials']['token'],
            expires_at: response['credentials']['expires_at'],
            refresh_token: response['credentials']['refresh_token'],
          }
        end
      end

      def call(period)
        client = Client.new(
          account: data['account'],
          profile: data['profile'],
          token: data['token'],
          period: period,
        )

        client.metrics
      end
    end
  end
end

require 'trepscore/services/google_analytics/client'
