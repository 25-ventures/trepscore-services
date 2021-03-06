lib_file = File.expand_path("../lib/trepscore/services.rb", __FILE__)
File.read(lib_file) =~ /\bVERSION\s*=\s*["'](.+?)["']/
version = $1

Gem::Specification.new do |spec|
  spec.specification_version = 2 if spec.respond_to? :specification_version=
  spec.required_rubygems_version = Gem::Requirement.new('>= 1.3.5') if spec.respond_to? :required_rubygems_version=

  spec.name    = 'trepscore-services'
  spec.version = version

  spec.summary = 'Trepscore Services client code'

  spec.authors  = ['Ryan Faerman']
  spec.email    = 'ryan@trepscore.com'
  spec.homepage = 'https://github.com/trepscore/trepscore-services'

  spec.add_dependency 'descendants_tracker',  '~> 0.0.4'
  spec.add_dependency 'activesupport'

  #=============================================================================
  # Service Specific dependencies get added here
  #=============================================================================

  # Pipedrive
  spec.add_dependency 'pipedrive-client'

  # GitHub
  spec.add_dependency 'octokit',              '>= 3.3.0'
  spec.add_dependency 'omniauth-github'

  # Quickbooks
  spec.add_dependency 'quickbooks-ruby'
  # spec.add_dependency 'omniauth-quickbooks' #TODO: uncomment when PR is merged

  # Google Analytics
  spec.add_dependency 'legato', '>= 0.3.3'
  spec.add_dependency 'omniauth-google-oauth2', '>= 0.2.5'

  # Basecamp
  spec.add_dependency 'faraday'
  spec.add_dependency 'omniauth-basecamp'

  # Trello
  spec.add_dependency 'ruby-trello'
  spec.add_dependency 'omniauth-trello'

  #=============================================================================


  spec.files = %w(Gemfile LICENSE README.md CONTRIBUTING.md Rakefile)
  spec.files << "trepscore-services.gemspec"
  spec.files += Dir.glob("lib/**/*.rb")
  spec.files += Dir.glob("spec/**/*.rb")

  spec.require_paths = ['lib', 'lib/trepscore']

  dev_null    = File.exist?('/dev/null') ? '/dev/null' : 'NUL'
  git_files   = `git ls-files -z 2>#{dev_null}`
  spec.files &= git_files.split("\0") if $?.success?
end
