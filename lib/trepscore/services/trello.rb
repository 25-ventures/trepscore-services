require 'omniauth-trello'
require 'trello'

module TrepScore
  module Services
    class Trello < Service
      category :project_management

      url 'https://trello.com'
      logo_url 'https://trepscore-production.s3.amazonaws.com/assets/trello/trello-icon-blue.png'

      oauth(:trello) do |config|
        config.scope = 'read,write,account'
        config.options = { app_name: 'TrepScore', expiration: 'never' }
        config.filter = proc do |response, params|
          {
            token: response['credentials']['token'],
            secret: response['credentials']['secret'],
          }
        end
      end


      def call(period)

        cards = []

        boards.each do |board|
          cards += client.get("/boards/#{board.id}/cards/all").json_into(::Trello::Card)
        end

        remove_future(boards, period)
        remove_future(cards, period)

        closed_ones = ->(item){ item.closed }

        closed_cards, open_cards = cards.partition &closed_ones

        past_due_cards = open_cards.select do |c|
          !c.badges['due'].nil? && Date.parse(c.badges['due']) < period.begin
        end

        closed_boards = boards.select &closed_ones

        {
          projects: boards.count,
          new_projects: filter_by_created_at(boards, period).count,
          completed_projects: closed_boards.count,
          pending_tasks: open_cards.count,
          new_tasks: filter_by_created_at(cards, period).count,
          completed_tasks: closed_cards.count,
          past_due_tasks: past_due_cards.count,
        }
      end

      def boards
        @boards ||= begin
          username = client.find(:members, :me).username
          client.get("/members/#{username}/boards").json_into(::Trello::Board)
        end
      end

      private
        def client
          @client ||= ::Trello::Client.new(
            :consumer_key => ENV['TRELLO_KEY'],
            :consumer_secret => ENV['TRELLO_SECRET'],
            :oauth_token => data['token'],
            :oauth_token_secret => data['secret']
          )
        end

        def remove_future(items, period)
          items.reject! do |item|
            created_at_for(item) > period.end
          end
        end

        def filter_by_created_at(items, period)
          items.select do |item|
            created_in?(item, period)
          end
        end

        def created_in?(item, period)
          period.cover? created_at_for(item)
        end

        def created_at_for(item)
          Time.at(item.id.slice(0..7).hex)
        end

    end
  end
end
