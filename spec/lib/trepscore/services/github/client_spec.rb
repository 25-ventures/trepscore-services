require 'trepscore/services/github'

describe TrepScore::Services::GitHub::Client do
  let(:octokit) do
    double('Octokit client', commits: [], list_issues: [], same_options?: false)
  end

  let(:end_date) { Date.today }
  let(:start_date) { Date.today - 7 }

  let(:data) do
    {
      repo: '25-ventures/trepscore-services',
      token: 'secret-token',
      id: '123456',
      period: (start_date..end_date)
    }
  end

  before do
    allow(Octokit::Client).to receive(:new) { octokit }
  end

  let(:metrics) { described_class.new(data).metrics }

  it 'returns the total number of commits' do
    allow(octokit).to receive(:commits) do
      [
        { commit: { author: { date: (Date.today - 5).to_time } } },
        # Be sure to test we can find things within the end date
        { commit: { author: { date: (Date.today).to_time + 1000 } } },
        { commit: { author: { date: (Date.today + 1).to_time } } },
      ]
    end

    expect(metrics[:total_commits]).to equal(2)
  end

  context 'issues' do
    before do
      allow(octokit).to receive(:list_issues) do
        [
          { created_at: (Date.today - 5).to_time, state: 'open' },
          { created_at: (Date.today - 4).to_time, state: 'closed' },
          { created_at: (Date.today - 3).to_time, state: 'open', pull_request: {} },
          # Be sure to test we can find things within the end date
          { created_at: (Date.today).to_time + 1000, state: 'open' },
          { created_at: (Date.today + 1).to_time },
        ]
      end
    end

    it 'returns the number of issues open in the period' do
      expect(metrics[:open_issues]).to eq 2
    end

    it 'returns the number of issues closed in the period' do
      expect(metrics[:closed_issues]).to eq 1
    end

    it 'returns the number of pull requests in the period' do
      expect(metrics[:pull_requests]).to eq 1
    end
  end
end
