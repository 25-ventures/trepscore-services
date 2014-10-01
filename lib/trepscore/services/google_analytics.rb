require 'omniauth-google-oauth2'

module TrepScore
  module Services
    class GoogleAnalytics < Service
      SCOPE = 'email https://www.googleapis.com/auth/analytics.readonly'
      category :analytics

      required do
        string :account
        string :profile
      end

      url 'http://www.google.com/analytics/'

      maintained_by github: 'federomero',
                    email:  'hi@federomero.uy',
                    web:    'http://federomero.uy'

      oauth(provider: :google_oauth2, scope: SCOPE) do |response, _|
        {
          token: response['credentials']['token'],
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
