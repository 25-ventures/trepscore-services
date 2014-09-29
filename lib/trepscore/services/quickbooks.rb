# TODO: there is a pull request fixing an issue within this gem, uncomment when merged
# require 'omniauth-quickbooks'

require 'quickbooks-ruby'

# Monkey-patch quickbooks-ruby so we can access the profile & loss report
# which has all the data points we're looking for
module Quickbooks
  module Service
    class Reports < BaseService
      def profit_and_loss(params = {})
        run_report('ProfitAndLoss', params)

        {
          totalIncome: value_of('Income'),
          grossProfit: value_of('GrossProfit'),
          expenses: value_of('Expenses'),
          netOperatingIncome: value_of('NetOperatingIncome'),
          otherExpenses: value_of('OtherExpenses'),
          netOtherIncome: value_of('NetOtherIncome'),
          netIncome: value_of('NetIncome'),
        }
      end

      def balance_sheet(params = {})
        run_report('BalanceSheet', params)

        {
          totalAssets: value_of("TotalAssets"),
          ar: value_of("AR"),
          ap: value_of("AP"),
          liabilities: value_of("Liabilities"),
          equity: value_of("Equity"),
        }
      end

      def run_report(name, params = {})
        url = url_for_resource("reports/#{name}")
        url = add_query_string_to_url(url, params)
        do_http_get(url)
        @last_response_xml
      end

      def value_of(group)
        nodes = @last_response_xml.css("Row[group=#{group}] Summary ColData:last")
        if nodes.nil? || nodes.empty?
          0
        else
          # Convert to cent values
          (nodes.first['value'].to_f * 100).to_i
        end
      end
    end
  end
end

module TrepScore
  module Services
    class Quickbooks < Service
      title 'QuickBooks Online'
      category :bookkeeping
      url 'https://qbo.intuit.com'
      logo_url 'https://images.appcenter.intuit.com/Content/Static/4.12.0-trunk-2052/images/quickbooks_syncBig.png'

      maintained_by github: 'ryanfaerman',
                     email: 'ryan@trepscore.com',
                       web: 'http://www.trepscore.com'

      oauth(provider: :quickbooks) do |response, params|
        {
          realm_id: params['realmId'],
          token:    response['credentials']['token'],
          secret:   response['credentials']['secret'],
        }
      end

      def call(period)
        start_date = period.first.strftime('%Y-%m-%d')
        end_date   = period.last.strftime('%Y-%m-%d')

        begin
          balance_sheet = client.balance_sheet(start_date: start_date, end_date: end_date)
          profit_and_loss = client.profit_and_loss(start_date: start_date, end_date: end_date)
        rescue ::Quickbooks::AuthorizationFailure
          raise TrepScore::ConfigurationError.new(
            'It appears your QuickBooks authorization information is wrong')
        end

        {
          ar_balance: balance_sheet[:ar],
          # Invert this since in TrepScore we want everything positive
          ap_balance: -balance_sheet[:ap],
          revenue: profit_and_loss[:grossProfit],
          current_assets: balance_sheet[:totalAssets],
          # Same as above
          current_liabilities: -balance_sheet[:liabilities],
          income: profit_and_loss[:totalIncome],
          expenses: profit_and_loss[:expenses] + profit_and_loss[:otherExpenses],
        }
      end

      def client
        @client ||= begin
          ::Quickbooks::Service::Reports.new(
            company_id:   data['realm_id'],
            access_token: oauth_access_token
          )
        end
      end

      def oauth_consumer_token
        @oauth_consumer_token ||= OAuth::Consumer.new(
          ENV['QUICKBOOKS_KEY'],
          ENV['QUICKBOOKS_SECRET'],
          {
            site:               'https://oauth.intuit.com',
            request_token_path: '/oauth/v1/get_request_token',
            authorize_url:      'https://appcenter.intuit.com/Connect/Begin',
            access_token_path:  '/oauth/v1/get_access_token'
          }
        )
      end

      def oauth_access_token
        @oauth_access_token ||= begin
          OAuth::AccessToken.new(oauth_consumer_token, data['token'], data['secret'])
        end
      end
    end
  end
end
