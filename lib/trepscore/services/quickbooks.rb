# TODO: there is a pull request fixing an issue within this gem, uncomment when merged
# require 'omniauth-quickbooks'

require 'quickbooks-ruby'

# Monkey-patch quickbooks-ruby so we can access the profile & loss report
# which has all the data points we're looking for
module Quickbooks
  module Service
    class Reports < BaseService

      def profit_and_loss(params = {})
        url = url_for_resource('reports/ProfitAndLoss')
        url = add_query_string_to_url(url, params)
        do_http_get(url)
        xml = @last_response_xml

        {
                  reportName: xml.css('ReportName').text,
                 reportBasis: xml.css('ReportBasis').text,
                 startPeriod: xml.css('StartPeriod').text.to_date,
                   endPeriod: xml.css('EndPeriod').text.to_date,
                 totalIncome: value_of('Income'),
                 grossProfit: value_of('GrossProfit'),
                    expenses: value_of('Expenses'),
          netOperatingIncome: value_of('NetOperatingIncome'),
               otherExpenses: value_of('OtherExpenses'),
              netOtherIncome: value_of('NetOtherIncome'),
                   netIncome: value_of('NetIncome'),
        }
      end

      def value_of(group)
        nodes = @last_response_xml.css("Row[group=#{group}] Summary ColData:last")
        value = if nodes.nil? || nodes.empty?
          0.0
        else
          nodes.first['value'].to_f
        end

        value
      end
    end
  end
end

module TrepScore
  module Services
    class Quickbooks < Service
      title 'QuickBooks Online'

      category :bookkeeping

      url   'https://qbo.intuit.com'

      logo_url 'https://images.appcenter.intuit.com/Content/Static/4.12.0-trunk-2052/images/quickbooks_syncBig.png'

      maintained_by github: 'ryanfaerman',
                     email: 'ryan@trepscore.com',
                       web: 'http://www.trepscore.com'

      oauth(provider: :quickbooks) do |response, params|
        {
          realm_id: params['realmId'],
          token: response['credentials']['token'],
          secret: response['credentials']['secret'],
        }
      end

      def call(period)
        start_date = period.first.strftime('%Y-%m-%d')
        end_date   = period.last.strftime('%Y-%m-%d')

        report = client.profit_and_loss({start_date: start_date, end_date: end_date})

        {
          income: report[:totalIncome],
          expenses: report[:expenses] + report[:otherExpenses],
        }
      end

      def test

      end

      def client
        @client ||= begin
          ::Quickbooks::Service::Reports.new({
            company_id: data['realm_id'],
            access_token: oauth_access_token
          })
        end
      end

      def oauth_consumer_token
          @oauth_consumer_token ||= OAuth::Consumer.new(ENV['QUICKBOOKS_KEY'], ENV['QUICKBOOKS_SECRET'], {
              :site                 => "https://oauth.intuit.com",
              :request_token_path   => "/oauth/v1/get_request_token",
              :authorize_url        => "https://appcenter.intuit.com/Connect/Begin",
              :access_token_path    => "/oauth/v1/get_access_token"
          })
        end

        def oauth_access_token
          @oauth_access_token ||= begin
            OAuth::AccessToken.new(oauth_consumer_token, data['token'], data['secret'])
          end
        end

    end
  end
end
