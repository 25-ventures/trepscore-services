require 'trepscore/services/github'

describe ::Github::Client do
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

  it 'returns the total number of commits' do
    allow(octokit).to receive(:commits) do
      [
        { commit: { author: { date: (Date.today - 5).to_time } } },
        { commit: { author: { date: (Date.today - 1).to_time } } },
        { commit: { author: { date: (Date.today + 1).to_time } } },
      ]
    end
    metrics = Github::Client.new(data).metrics
    expect(metrics[:total_commits]).to equal(2)
  end

  it 'returns the number of issues open in the period' do
    allow(octokit).to receive(:list_issues) do
      [
        { created_at:  (Date.today - 5).to_time, closed_at: (Date.today - 5).to_time },
        { created_at:  (Date.today - 1).to_time, closed_at: (Date.today - 1).to_time },
        { created_at:  (Date.today + 1).to_time, closed_at: (Date.today + 1).to_time },
      ]
    end
    metrics = Github::Client.new(data).metrics
    expect(metrics[:open_issues]).to equal(2)
  end
end
