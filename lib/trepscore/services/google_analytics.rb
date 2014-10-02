require 'omniauth-google-oauth2'

module TrepScore
  module Services
    class GoogleAnalytics < Service
      SCOPE = 'analytics.readonly,userinfo.profile'
      category :analytics

      required do
        string :account
        string :profile
      end

      url 'http://www.google.com/analytics/'

      maintained_by github: 'federomero',
                    email:  'hi@federomero.uy',
                    web:    'http://federomero.uy'

      # The prompt param is needed so we get a refresh_token
      oauth(provider: :google_oauth2, scope: SCOPE, options: { prompt: 'consent' }) do |response, _|
        {
          token: response['credentials']['token'],
          expires_at: response['credentials']['expires_at'],
          refresh_token: response['credentials']['refresh_token'],
        }
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
