require 'omniauth-basecamp'

module TrepScore
  module Services
    class Basecamp < Service
      category :project_management

      required do
        string :account
      end

      url 'https://basecamp.com'

      oauth(:basecamp) do |config|
        config.filter  = proc do |response, params|
          {
            token: response['credentials']['token'],
            expires_at: response['credentials']['expires_at'],
            refresh_token: response['credentials']['refresh_token'],
          }
        end
      end

      def accounts
        info = make_request('https://launchpad.37signals.com/authorization.json')

        unless info.nil?
          {}.tap do |result|
            info['accounts'].each do |a|
              result[a['id']] = a['name']
            end
          end
        end
      end

      def call(period)
        # TODO: paginate?
        projects = make_request(build_url('projects'))
        todos = make_request(build_url('todos'))

        {
          projects: filter_by_date(projects, period).count,
          todos: filter_by_date(todos, period).count
        }
      end

      private

        def make_request(url)
          resp = Faraday.get do |req|
            req.url url
            req.headers['Authorization'] = "Bearer #{data['token']}"
            req.headers['User-Agent'] = 'TrepScore (engineering@trepscore.com)'
          end

          if resp.success?
            JSON.parse(resp.body)
          end
        end

        def build_url(endpoint)
          "https://basecamp.com/#{data['account']}/api/v1/#{endpoint}.json"
        end

        def filter_by_date(items, period)
          items.select do |item|
            period.cover? DateTime.parse(item['created_at'])
          end
        end
    end
  end
end
