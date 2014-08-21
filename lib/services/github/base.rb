require 'octokit'
module Github
  
  class Base
    #Constants for this class comes here
    CLASS_NAME_WITH_ISSUE = "Issues"
    CLOSED_ISSUES = "closed"   
    COMMITS_RESOURCE_PATH = "commits"
    CODES_RESOURCE_PATH = "codes"
    FILES_RESOURCE_PATH = "files"
    FILE_TYPE_BLOB = "blob"
    ISSUES_RESOURCE_PATH = "issues"
    OPEN_ISSUES = "open"
    

    def initialize(options = {})
      @options = options      
      authenticate
      enable_pagination_by_default
    end

    def authenticate(client_id = @options[:client_id], client_secret = @options[:client_secret], user_name = @options[:user_name], user_repo = @options[:user_repo])
      client = Octokit::Client.new(:client_id => @options[:client_id], :client_secret => @options[:client_secret], :user_name => @options[:user_name], :user_repo => @options[:user_repo])
    end

    def metrics
      metrics = {total: all.join.to_i}
      metrics
    end
  
    def get_commits
       Octokit.commits("#{slug}").count      
    end

    def get_sha_for_latest_commit
      commits = Octokit.commits("#{slug}")
      data = [(commits || [])].flatten
      @options[:sha] =  data.first['sha']
    end

    def get_open_issues
      issues = Octokit.issues("#{slug}", :state => OPEN_ISSUES).count
    end 
    
    def get_closed_issues
      issues = Octokit.issues("#{slug}", :state => CLOSED_ISSUES).count
    end 
   
    def get_files
      @files = Octokit.tree("#{slug}", "#{sha_slug}", :recursive => true).tree
    end 

    def get_no_of_files
      get_files.count
    end

    def get_lines_of_codes
      get_files
      lines_of_codes = 0
      @files.each do |file|
        if file[:type] == FILE_TYPE_BLOB
          codes_encoded =  Octokit.contents("#{slug}",:path => file[:path])
          codes_decoded = Base64.decode64(codes_encoded.content)
          lines_of_codes += codes_decoded.count("\n")
        end
      end 
      lines_of_codes     
    end 

    def all(options = {})
      data = []
      data << get_commits if resource_path.start_with?(COMMITS_RESOURCE_PATH)
      data << get_open_issues if resource_path.start_with?(OPEN_ISSUES)
      data << get_closed_issues if resource_path.start_with?(CLOSED_ISSUES)
      data << get_no_of_files if resource_path.start_with?(FILES_RESOURCE_PATH)
      data << get_lines_of_codes if resource_path.start_with?(CODES_RESOURCE_PATH)
      data	
    end
   
    def enable_pagination_by_default  
      Octokit.auto_paginate = true
    end      

    def slug
      "#{user}/#{repo}"
    end

    def sha_slug
      get_sha_for_latest_commit
      @options[:sha]
    end
 
    def user
      @options[:user_name]
    end

    def repo
      @options[:user_repo]
    end

    def resource_path
      #The resource path should match the camelCased class name with the
      #first letter downcased.  
      klass = self.class.name.split('::').last
      klass[0] = klass[0].chr.downcase
      klass
    end

    def resource(klass_name)
      klass_name = klass_name.to_s.split('_').map(&:capitalize).join
      _klasses[klass_name] ||= begin
        klass = Object.const_get "::Github::#{klass_name}"
        klass.new @options
      end
    end

   private 
      def _klasses
        @_klasses ||= {}
      end

  end
end
