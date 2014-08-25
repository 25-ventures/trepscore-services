require 'octokit'

class Github::Client
  attr_accessor :repo, :token, :id

  def initialize(data)
    self.repo = data[:repo]
    self.token = data[:token]
    self.id = data[:id]
  end

  def metrics
    {
      total_commits: total_commits,
      open_issues: open_issues,
      closed_issues: closed_issues,
    }
  end

  protected

  def total_commits
    repo_stats = octokit.contributors_stats(repo)
    raise Github::StatsNotReady if repo_stats.nil?
    repo_stats.inject(0) {|sum, stat| sum += stat[:total] }
  end

  def open_issues
    issues.select{|i| i[:state] == 'open'}.count
  end

  def closed_issues
    issues.select{|i| i[:state] == 'closed'}.count
  end

  def octokit
    @octokit ||=  Octokit::Client.new(access_token: token)
  end

  def issues
    @issues ||= octokit.list_issues(repo, state: :all)
  end
end
