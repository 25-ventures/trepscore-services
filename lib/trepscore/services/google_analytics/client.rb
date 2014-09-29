require 'legato'

module TrepScore
  module Services
    class GoogleAnalytics
      class Page
        extend Legato::Model

        metrics :users, :newUsers, :percentNewSessions, :bounceRate, :avgSessionDuration, :pageviews
      end


      class Client
        attr_accessor :account_name, :profile_name, :access_token, :period

        def initialize(data)
          self.period = data[:period]
          self.account_name = data[:account]
          self.profile_name = data[:profile]
          self.access_token = data[:access_token]
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
