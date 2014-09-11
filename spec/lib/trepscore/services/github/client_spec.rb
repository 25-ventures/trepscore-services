require 'trepscore/services/github'

describe ::Github::Client do
  let(:octokit) { double("Octokit client", contributors_stats: [], list_issues: []) }
  let(:data) { { repo: '25-ventures/trepscore-services', token: 'secret-token', id: '123456' } }

  before do
    allow(Octokit::Client).to receive(:new) { octokit }
  end

  it 'returns the total number of commits' do
    allow(octokit).to receive(:contributors_stats) do
      [ { total: 1 }, { total: 2 }, { total: 3 } ]
    end
    metrics = Github::Client.new(data).metrics
    expect(metrics[:total_commits]).to equal(6)
  end

  it 'returns the number of open and closed issues' do
    allow(octokit).to receive(:list_issues) do
      [ { state: 'open' }, { state: 'closed' }, { state: 'open' } ]
    end
    metrics = Github::Client.new(data).metrics
    expect(metrics[:open_issues]).to equal(2)
    expect(metrics[:closed_issues]).to equal(1)
  end

  it 'raises an error if stats are not ready' do
    allow(octokit).to receive(:contributors_stats) { nil }

    stats_not_ready = begin
                        Github::Client.new(data).metrics
                        false
                      rescue Github::StatsNotReady
                        true
                      end

    expect(stats_not_ready).to be_truthy
  end
end
