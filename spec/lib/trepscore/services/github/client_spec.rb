require 'trepscore/services/github'

describe TrepScore::Services::GitHub::Client do
  let(:octokit) do
    double('Octokit client', commits: [], issues: [], same_options?: false)
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
    allow(octokit).to receive(:commits) do |repo, _, since:, until:, page: 1|
      case page
      when 1
        [
          { sha: 1, commit: { author: { date: (Date.today - 5).to_time } } },
          # Be sure to test we can find things within the end date
          { sha: 2, commit: { author: { date: (Date.today).to_time + 1000 } } },
          { sha: 3, commit: { author: { date: (Date.today + 1).to_time } } },
        ]
      when 2
        [
          # Repeat this on purpose
          { sha: 3, commit: { author: { date: (Date.today + 1).to_time } } },
        ]
      else
        []
      end
    end

    expect(metrics[:total_commits]).to eq(2)
  end

  context 'issues' do
    before do
      allow(octokit).to receive(:issues) do |repo, state:, since:, page: 1, direction:|
        case page
        when 1
          [
            { number: 1, created_at: (Date.today - 10).to_time, closed_at: (Date.today - 5).to_time },
            { number: 2, created_at: (Date.today - 5).to_time },
            { number: 3, created_at: (Date.today - 4).to_time, closed_at: (Date.today - 2).to_time},
          ]
        when 2
          [
            { number: 4, created_at: (Date.today - 3).to_time, pull_request: {} },
            # Be sure to test we can find things within the end date
            { number: 5, created_at: (Date.today).to_time + 1000 },
            { number: 6, created_at: (Date.today - 1).to_time, closed_at: (Date.today + 1).to_time },
            { number: 7, created_at: (Date.today + 1).to_time },
          ]
        else
          []
        end
      end
    end

    it 'returns the number of issues open in the period' do
      expect(metrics[:open_issues]).to eq 4
    end

    it 'returns the number of issues closed in the period' do
      expect(metrics[:closed_issues]).to eq 2
    end

    it 'returns the number of pull requests in the period' do
      expect(metrics[:pull_requests]).to eq 1
    end
  end
end
