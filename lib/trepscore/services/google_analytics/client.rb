require 'legato'

module TrepScore
  module Services
    class GoogleAnalytics
      class Page
        extend Legato::Model

        metrics :users, :newUsers, :percentNewSessions, :bounceRate, :avgSessionDuration, :pageviews
      end

      class Client
        attr_accessor :account_name, :profile_name, :token, :period

        def initialize(data)
          self.account_name = data[:account]
          self.profile_name = data[:profile]
          self.token = data[:token]
          self.period = data[:period]
        end

        def metrics
          result = Page.results(profile, start_date: start_date, end_date: end_date).first

          {
            users: result.users,
            new_users: result.newUsers,
            percent_new_sessions: result.percentNewSessions,
            bounce_rate: result.bounceRate,
            avg_session_duration: result.avgSessionDuration,
            page_views: result.pageviews
          }
        end

        protected

        def access_token
          @access_token ||= begin
            client = OAuth2::Client.new(ENV['GOOGLE_OAUTH2_KEY'], ENV['GOOGLE_OAUTH2_SECRET'], {
              authorize_url: 'https://accounts.google.com/o/oauth2/auth',
              token_url: 'https://accounts.google.com/o/oauth2/token',
            })

            client.auth_code.authorize_url(access_type: 'offline')

            OAuth2::AccessToken.from_hash(client, access_token: token)
          end
        end

        def user
          @user ||= Legato::User.new(access_token)
        end

        def account
          @account ||= user.accounts.find{|a| a.name == account_name }
        end

        def profile
          @profile ||= account.profiles.find{|p| p.name == profile_name }
        end

        def start_date
          @start_date ||= period.first
        end

        def end_date
          @end_date ||= period.last
        end
      end
    end
  end
end
