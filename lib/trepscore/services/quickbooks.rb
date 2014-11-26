# TODO: there is a pull request fixing an issue within this gem, uncomment when merged
# require 'omniauth-quickbooks'

require 'quickbooks-ruby'

# Monkey-patch quickbooks-ruby so we can access the profit & loss and expense
# reports which have all the data points we're looking for
module Quickbooks
  module Service
    class Reports < BaseService
      def profit_and_loss(params = {})
        run_report('ProfitAndLoss', params)
      end

      def balance_sheet(params = {})
        run_report('BalanceSheet', params)
      end

      def run_report(name, params = {})
        url = url_for_resource("reports/#{name}")
        url = add_query_string_to_url(url, params)
        do_http_get(url)
        @last_response_xml
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

      oauth(:quickbooks) do |config|
        config.filter = proc do |response, params|
          {
            realm_id: params['realmId'],
            token:    response['credentials']['token'],
            secret:   response['credentials']['secret'],
          }
        end
      end

      def call(period)
        start_date = period.first.strftime('%Y-%m-%d')
        end_date   = period.last.strftime('%Y-%m-%d')

        begin
          profit_and_loss = client.profit_and_loss(start_date: start_date, end_date: end_date)
          balance_sheet = client.balance_sheet(start_date: start_date, end_date: end_date)
        rescue ::Quickbooks::AuthorizationFailure
          raise TrepScore::ConfigurationError.new(
            'It appears your QuickBooks authorization information is wrong')
        end

        profit_and_loss = xml_to_hash(profit_and_loss)
        balance_sheet = xml_to_hash(balance_sheet)

        # Example Profit and Loss report after the above:
        #
        # {"total job materials"=>80282, "total labor"=>30000, "total landscaping services"=>651397, "total income"=>1020077, "total cost of goods sold"=>40500, "gross profit"=>979577, "total automobile"=>46337, "total job expenses"=>95789, "total legal & professional fees"=>117000, "total maintenance and repair"=>94000, "total utilities"=>33139, "total expenses"=>523731, "net operating income"=>455846, "total other expenses"=>291600, "net other income"=>-291600, "net income"=>164246}

        # Example Balance Sheet report after the above:
        #
        # {"total bank accounts"=>200100, "total accounts receivable"=>528152, "total other current assets"=>265877, "total current assets"=>994129, "total truck"=>1349500, "total fixed assets"=>1349500, "total assets"=>2343629, "total accounts payable"=>160267, "total credit cards"=>15772, "total other current liabilities"=>437093, "total current liabilities"=>613133, "total long-term liabilities"=>2500000, "total liabilities"=>3113133, "total equity"=>-769504, "total liabilities and equity"=>2343629}

        {
          revenue: profit_and_loss['total income'],
          cogs: profit_and_loss['total cost of goods sold'],
          expenses: profit_and_loss['total expenses'],
          other_expenses: profit_and_loss['total other expenses'],

          cash: balance_sheet['total bank accounts'],
          ar_balance: balance_sheet['total accounts receivable'],
          current_assets: balance_sheet['total current assets'],
          other_current_assets: balance_sheet['total other current assets'],
          credit_cards: balance_sheet['total credit cards'],
          ap_balance: balance_sheet['total accounts payable'],
          current_liabilities: balance_sheet['total current liabilities'],
          other_current_liabilities: balance_sheet['total other current liabilities'],
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

      def xml_to_hash(xml)
        {}.tap do |result|
          # Take each column from the Summary elements, get the values, and group them
          xml.css("Row Summary ColData").map {|n| n['value'] }.each_slice(2) do |name, value|
            # Downcase to avoid any issues with casing
            result[name.downcase] = convert_to_cents(value)
          end
        end
      end

      def convert_to_cents(value)
        (value.to_f * 100).to_i
      end
    end
  end
end
