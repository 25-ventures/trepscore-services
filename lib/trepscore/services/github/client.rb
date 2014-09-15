require 'octokit'

class Github::Client
  attr_accessor :repo, :token, :id, :period

  def initialize(data)
    self.period = data[:period]
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

  def start_time
    period.first.to_time
  end

  def end_time
    period.last.to_time
  end

  def total_commits
    more = true
    page = 0
    total = 0
    while more
      commits = octokit.commits(repo, nil, since: start_time, page: page)

      relevant = commits.select{|c| c[:commit][:author][:date] <= end_time }.length
      # binding.pry
      total += relevant
      if commits.length == relevant && relevant > 0
        page += 1
      else
        more = false
      end
    end

    total
  end

  def open_issues
    more = true
    page = 0
    total = 0
    while more

      # list issues updated after start time
      options = {
        state: :all,
        since: start_time,
        sort: 'created',
        direction: 'asc',
        page: page,
      }

      issues = octokit.list_issues(repo, options)

      relevant = issues.select{|i| i[:created_at] <= end_time }.length

      total += relevant
      if issues.length == relevant && relevant > 0
        page += 1
      else
        more = false
      end
    end

    total
  end

  def closed_issues
    more = true
    page = 0
    total = 0
    while more

      # list issues updated after start time
      options = {
        state: :closed,
        since: start_time,
        sort: 'created',
        direction: 'asc',
        page: page,
      }

      issues = octokit.list_issues(repo, options)

      relevant = issues.select{ |i| i[:closed_at] <= end_time }.length

      total += relevant

      if issues.length == 0 || issues.any?{ |i| i[:created_at] > end_time }
        more = false
      else
        page += 1
      end
    end

    total
  end

  def octokit
    @octokit ||=  Octokit::Client.new(access_token: token)
  end
end
