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
        projects = collect(build_url('projects'))
        remove_future(projects, period)
        remove_trashed(projects, period)

        archived_projects = collect(build_url('projects/archived'))
        remove_future(archived_projects, period)
        remove_trashed(archived_projects, period)

        todos = collect(build_url('todos'), paging: true)
        remove_future(todos, period)
        remove_trashed(todos, period)

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

        def collect(url, paging: false)
          result = []

          page = 1
          loop do
            items = make_request("#{url}?page=#{page}")

            if items.nil?
              break
            else
              result += items
              if !paging || items.empty?
                break
              end
              page += 1
            end
          end

          result
        end

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

        def created_at_for(item)
          DateTime.parse(item['created_at'])
        end

        def remove_future(items, period)
          items.reject! do |item|
            created_at_for(item) > period.end
          end
        end

        def created_in?(item, period)
          period.cover? created_at_for(item)
        end

        def remove_trashed(items, period)
          items.reject! do |item|
            !created_in?(item, period) && item['trashed']
          end
        end

        def filter_by_created_at(items, period)
          items.select do |item|
            created_in?(item, period)
          end
        end
    end
  end
end
