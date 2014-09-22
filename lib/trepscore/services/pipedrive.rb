require 'pipedrive'

module TrepScore
  module Services
    class Pipedrive < Service
      category :crm

      required do
        string :token
      end

      url 'http://www.pipedrive.com'

      def call(period)
        @period = period
        {
          contacts: contacts,
          organizations: organizations,
          deals_won: deals_won,
          deals_lost: deals_lost,
          leads: nil,
          pipeline_value: pipeline_value
        }
      end

      def test
        client.validate_authorization
      end

      private

      def client
        @client ||= ::Pipedrive::Client.new(api_token: data['token'])
      end

      def contacts(period = @period)
        persons = 0

        client.persons(sort_by: :add_time, sort_mode: :desc).each do |person|
          persons += 1 if period.cover? Date.parse(person.add_time)
        end

        persons
      end

      def organizations(period = @period)
        items = 0

        client.organizations(sort_by: :add_time, sort_mode: :desc).each do |item|
          items += 1 if period.cover? Date.parse(item.add_time)
        end

        items
      end

      def deals_won(period = @period)
        items = 0

        client.deals(sort_by: :update_time, sort_mode: :desc).each do |item|
          timely_update = period.cover?(Date.parse(item.update_time))
          timely_won = !item.won_time.nil? && period.cover?(Date.parse(item.won_time))

          items += 1 if timely_update && timely_won
        end

        items
      end

      def deals_lost(period = @period)
        items = 0

        client.deals(sort_by: :update_time, sort_mode: :desc).each do |item|
          timely_update = period.cover?(Date.parse(item.update_time))
          timely_lost = !item.lost_time.nil? && period.cover?(Date.parse(item.lost_time))

          items += 1 if timely_update && timely_lost
        end

        items
      end

      def pipeline_value(period = @period)
        value = 0

        client.deals(sort_by: :update_time, sort_mode: :desc).each do |item|
          timely_update = period.cover?(Date.parse(item.update_time))
          if timely_update && item.active && !item.lost_time.nil?
            value += item * 100
          end
        end

        value
      end
    end
  end
end
