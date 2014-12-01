require 'trepscore/services/quickbooks'

describe TrepScore::Services::Quickbooks do
  let(:period) { (Date.today - 6)..Date.today }
  let(:data) { {} }
  let(:client) { double }

  subject { described_class.new(data) }

  before do
    allow(subject).to receive(:client) { client }
  end

  it 'handles authorization failures' do
    allow(client).to receive(:profit_and_loss).and_raise(::Quickbooks::AuthorizationFailure)

    expect { subject.call(period) }.to raise_error(TrepScore::ConfigurationError)
  end

  context 'when calling the API' do
    def read_xml_file(name)
      Nokogiri(File.read(File.expand_path("./spec/data/#{name}")))
    end

    let(:profit_and_loss) { read_xml_file('profit_and_loss.xml') }
    let(:balance_sheet) { read_xml_file('balance_sheet.xml') }

    before do
      allow(client).to receive(:profit_and_loss) { profit_and_loss }
      allow(client).to receive(:balance_sheet) { balance_sheet }
    end

    it 'extracts the right values from the XML' do
      result = subject.call(period)

      {
        revenue: 1020077,
        # COGS has been removed from this file to test the handling of missing fields
        cogs: 0,
        expenses: 523731,
        other_expenses: 291600,

        cash: 200100,
        ar_balance: 528152,
        current_assets: 994129,
        other_current_assets: 265877,
        credit_cards: 15772,
        ap_balance: 160267,
        current_liabilities: 613133,
        other_current_liabilities: 437093
      }.each do |field, value|
        expect(result[field]).to(eq(value), "expected #{value} for field #{field}, but got #{result[field]}")
      end
    end
  end
end
