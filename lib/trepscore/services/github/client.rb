require 'octokit'

class TrepScore::Services::GitHub::Client
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
      pull_requests: pull_requests
    }
  end

  protected

  def start_date
    @start_date ||= period.first
  end

  def end_date
    @end_date ||= period.last
  end

  def start_time
    @start_time ||= start_date.to_time
  end

  def end_time
    # Since dates turned into time have a time of 00:00:00, go to the next day
    @end_time ||= (end_date + 1).to_time
  end

  def within_range?(date)
    return false if date.nil?

    date = date.to_date
    date >= start_date && date <= end_date
  end

  def filter_by_date(items, &date_block)
    items.select do |i|
      within_range? date_block.call(i)
    end
  end

  def paging(unique_key, &block)
    result = {}

    page = 1
    in_current_range = false

    loop do
      filtered = block.call(page)

      if in_current_range
        if filtered.length == 0
          break
        end
      elsif filtered.length > 0
        in_current_range = true
      end

      filtered.each do |item|
        result[item[unique_key]] = item
      end
      page += 1

      if !in_current_range && page > 5
        # Give up
        break
      end
    end

    result.values
  end

  def total_commits
    paging(:sha) do |page|
      commits = octokit.commits(repo, nil, since: start_time, until: end_time, page: page)

      filter_by_date(commits) { |c| c[:commit][:author][:date] }
    end.length
  end

  def issues
    @issues ||= paging(:number) do |page|
      issues = octokit.issues(repo, state: :all, since: start_time, page: page, direction: 'asc')

      created = filter_by_date(issues) { |i| i[:created_at] }
      closed = filter_by_date(issues) { |i| i[:closed_at] }

      # These likely have issues in common, the paging method will merge them
      created + closed
    end
  end

  # GitHub issues include Pull Requests, filter those out
  def actual_issues
    @actual_issues ||= issues.select { |i| i[:pull_request].nil? }
  end

  def pull_requests
    issues.select { |i| !i[:pull_request].nil? }.length
  end

  def open_issues
    actual_issues.select { |i| within_range?(i[:created_at]) }.length
  end

  def closed_issues
    actual_issues.select { |i| within_range?(i[:closed_at]) }.length
  end

  def octokit
    @octokit ||= Octokit::Client.new(access_token: token)
  end
end
