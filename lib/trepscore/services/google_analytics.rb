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
          period: period,
          access_token: access_token,
          account: data['account'],
          profile: data['profile'],
        )

        client.metrics
      end

      protected

      # This is how I get the access token out of the token returned by google.
      # This should probably be handle by the library itself but I'm putting it here
      # for reference and so that the code I'm submitting works.
      def access_token
        client = OAuth2::Client.new(ENV['GOOGLE_CLIENT_ID'], ENV['GOOGLE_CLIENT_SECRET'], {
          authorize_url: 'https://accounts.google.com/o/oauth2/auth',
          token_url: 'https://accounts.google.com/o/oauth2/token',
        })

        client.auth_code.authorize_url({
          scope: SCOPE,
          redirect_uri: 'http://localhost:3000/auth/google_oauth2/callback',
          access_type: 'offline',
        })

        OAuth2::AccessToken.from_hash(client, access_token: data['token'])
      end
    end
  end
end

require 'trepscore/services/google_analytics/client'
