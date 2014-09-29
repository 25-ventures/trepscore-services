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
    allow(client).to receive(:balance_sheet).and_raise(::Quickbooks::AuthorizationFailure)

    expect { subject.call(period) }.to raise_error(TrepScore::ConfigurationError)
  end
end
