require 'omniauth-basecamp'
require 'faraday'

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
        # Pagination does not seem to work for the projects API
        projects = make_request(build_url('projects'))
        archived_projects = make_request(build_url('projects/archived'))

        todos = make_request(build_url('todos'), paging: true)

        # Remove trashed todos
        todos.reject! {|t| t['trashed'] }

        completed, pending = todos.partition {|t| t['completed'] }
        past_due = pending.select {|t| t['due_at'] && Date.parse(t['due_at']) < Date.today }

        {
          projects: projects.count,
          new_projects: filter_by_created_at(projects, period).count,
          completed_projects: archived_projects.count,
          pending_tasks: pending.count,
          new_tasks: filter_by_created_at(todos, period).count,
          completed_tasks: completed.count,
          past_due_tasks: past_due.count,
        }
      end

      private

        def make_request(url, paging: false)
          result = []

          page = 1
          loop do
            resp = Faraday.get do |req|
              req.url "#{url}?page=#{page}"
              req.headers['Authorization'] = "Bearer #{data['token']}"
              req.headers['User-Agent'] = 'TrepScore (engineering@trepscore.com)'
            end

            if resp.success?
              items = JSON.parse(resp.body)
              result += items
              if !paging || items.empty?
                break
              end
              page += 1
            else
              break
            end
          end

          result
        end

        def build_url(endpoint)
          "https://basecamp.com/#{data['account']}/api/v1/#{endpoint}.json"
        end

        def filter_by_created_at(items, period)
          items.select do |item|
            period.cover? DateTime.parse(item['created_at'])
          end
        end
    end
  end
end
