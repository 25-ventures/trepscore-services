module Github
  require 'octokit'

  autoload :Base, 'github/base'
  autoload :Client, 'github/client'
  autoload :ClosedIssues, 'github/closed_issues'
  autoload :Codes, 'github/codes'
  autoload :Commits, 'github/commits'
  autoload :Files, 'github/files'
  autoload :OpenIssues, 'github/open_issues'  
end

class Service::Github < Service
  string :client_id, :client_secret, :user_name, :user_repo
  category :developer_tools

  def call
    client = ::Github::Client.new(client_id: client_id, client_secret: client_secret, user_name: user_name, user_repo: user_repo)
    client.metrics
  end

  def client_id
    raise_config_error "Missing 'client_id'" if data[:client_id].to_s ==''
    data[:client_id]
  end

  def client_secret
    raise_config_error "Missing 'client secret'" if data[:client_secret].to_s==''
    data[:client_secret]
  end

  def user_name
    raise_config_error "Missing 'user_name'" if data[:user_name].to_s ==''
    data[:user_name]
  end

  def user_repo
    raise_config_error "Missing 'user_repo'" if data[:user_repo].to_s ==''
    data[:user_repo]
  end
end
