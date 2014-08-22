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
    }
  end

  def total_commits
    repo_stats = octokit.contributors_stats(repo)
    # user_stats = repo_stats.find { |stat| stat[:author][:id].to_s == id }
    # user_stats[:total]
    repo_stats.inject(0) {| sum, stat| sum += stat[:total] }
  end

  protected
  def octokit
    @octokit ||=  Octokit::Client.new(access_token: token)
  end
end
