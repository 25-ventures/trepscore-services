lib = "trepscore-services"
lib_file = File.expand_path("../lib/#{lib}.rb", __FILE__)
File.read(lib_file) =~ /\bVERSION\s*=\s*["'](.+?)["']/
version = $1
sha = `git rev-parse HEAD 2>/dev/null || echo unknown`
sha.chomp!
version << ".#{sha[0,7]}"

Gem::Specification.new do |spec|
  spec.specification_version = 2 if spec.respond_to? :specification_version=
  spec.required_rubygems_version = Gem::Requirement.new('>= 1.3.5') if spec.respond_to? :required_rubygems_version=

  spec.name    = lib
  spec.version = version

  spec.summary = 'Trepscore Services client code'

  spec.authors  = ['Ryan Faerman']
  spec.email    = 'ryan@trepscore.com'
  spec.homepage = 'https://github.com/trepscore/trepscore-services'

  spec.add_dependency 'faraday',              '>= 0.9.0'
  spec.add_dependency 'faraday_middleware',   '>= 0.9.1'
  spec.add_dependency 'multi_xml',            '>= 0'
  spec.add_dependency 'multi_json',           '>= 0'
  spec.add_dependency 'octokit',              '>= 3.0'
  
  ## Service Specific dependencies get added here
  


  spec.files = %w(Gemfile LICENSE README.md CONTRIBUTING.md Rakefile)
  spec.files << "#{lib}.gemspec"
  spec.files += Dir.glob("lib/**/*.rb")
  spec.files += Dir.glob("spec/**/*.rb")

  spec.require_paths = ['lib', 'lib/services']

  dev_null    = File.exist?('/dev/null') ? '/dev/null' : 'NUL'
  git_files   = `git ls-files -z 2>#{dev_null}`
  spec.files &= git_files.split("\0") if $?.success?
end
