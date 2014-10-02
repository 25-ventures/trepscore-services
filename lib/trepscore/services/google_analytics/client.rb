require 'legato'

module TrepScore
  module Services
    class GoogleAnalytics
      class Page
        extend Legato::Model

        metrics :sessions, :users, :newUsers, :percentNewSessions, :bounceRate,
          :avgSessionDuration, :pageviews
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
            total_visits: result.sessions,
            unique_visits: result.users,
            new_visits: result.newUsers,
            percent_new_visits: result.percentNewSessions,
            bounce_rate: result.bounceRate,
            average_visit_duration: result.avgSessionDuration,
            page_views: result.pageviews
          }
        end

        protected

        def access_token
          @access_token ||= begin
            # The first param is the Rack app, but we don't need it here
            middleware = OmniAuth::Strategies::GoogleOauth2.new(nil,
              client_id: ENV['GOOGLE_OAUTH2_KEY'],
              client_secret: ENV['GOOGLE_OAUTH2_SECRET'])

            OAuth2::AccessToken.from_hash(middleware.client, access_token: token)
          end
        end

        def user
          @user ||= Legato::User.new(access_token)
        end

        def account
          @account ||= begin
            account = user.accounts.find{|a| a.name == account_name }
            if account.nil?
              raise TrepScore::ConfigurationError.new("Could not find an account named '#{account_name}'")
            end
            account
          end
        end

        def profile
          @profile ||= begin
            profile = account.profiles.find{|p| p.name == profile_name }
            if profile.nil?
              raise TrepScore::ConfigurationError.new("Could not find a profile named '#{profile_name}'")
            end
            profile
          end
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
