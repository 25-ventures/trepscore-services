require 'trepscore/services/google_analytics'

describe TrepScore::Services::GoogleAnalytics::Client do
  let(:user) do
    double('Legato User', accounts: accounts)
  end

  let(:accounts) do
    [
      OpenStruct.new(name: 'other'),
      account,
      OpenStruct.new(name: 'another'),
    ]
  end

  let(:account) do
    OpenStruct.new(name: 'account-name', profiles: profiles)
  end

  let(:profiles) do
    [
      OpenStruct.new(name: 'other'),
      profile,
      OpenStruct.new(name: 'another'),
    ]
  end

  let(:profile) do
    double('Profile', name: 'profile-name')
  end

  let(:results) do
    [
      OpenStruct.new(
        users: 10,
        newUsers: 5,
        percentNewSessions: 75,
        bounceRate: 83,
        avgSessionDuration: 130,
        pageviews: 100
      )
    ]
  end

  let(:end_date) { Date.today }
  let(:start_date) { Date.today - 7 }

  let(:data) do
    {
      token: 'secret-token',
      account: 'account-name',
      profile: 'profile-name',
      period: (start_date..end_date)
    }
  end

  before do
    allow(Legato::User).to receive(:new) { user }
    allow(TrepScore::Services::GoogleAnalytics::Page)
      .to receive(:results)
      .with(profile, start_date: start_date, end_date: end_date)
      .and_return(results)
  end

  let(:metrics) { described_class.new(data).metrics }

  it 'returns the metrics' do
    expect(metrics[:users]).to eq(10)
  end
end
