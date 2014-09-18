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
    # We do weekly increments so we can use this
    Octokit.auto_paginate

    {
      total_commits: total_commits,
      open_issues: open_issues,
      closed_issues: closed_issues,
      pull_requests: pull_requests
    }
  end

  protected

  def start_time
    @start_time ||= period.first.to_time
  end

  def end_date
    @end_date ||= period.last
  end

  def total_commits
    commits = octokit.commits(repo, nil, since: start_time)

    # Filter down to those before the end date. Use a date because if we convert
    # the date to a time, it becomes that date at 00:00:00, so any commits later
    # in the day on that date are missed.
    commits.select { |c| c[:commit][:author][:date].to_date <= end_date }.length
  end

  def issues
    @issues ||= begin
      issues = octokit.list_issues(repo, state: :all, since: start_time)

      issues.select { |i| i[:created_at].to_date <= end_date }
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
    actual_issues.select { |i| i[:state] == 'open' }.length
  end

  def closed_issues
    actual_issues.select { |i| i[:state] == 'closed' }.length
  end

  def octokit
    @octokit ||= Octokit::Client.new(access_token: token)
  end
end
