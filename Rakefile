require 'rubygems'
require 'bundler/setup'

task :environment do
  require 'trepscore'
  TrepScore::Services.load
end

task :console => :environment do
  require 'pry'

  ARGV.clear
  Pry.start
end

namespace :test do
  task :interface do
    # Start the test interface in a thread
    t = Thread.new do
      require './test/trepscore-services-web'
      TrepScoreServicesWeb.run!
    end

    # Let Sinatra start
    sleep 3

    # Open this in the browser
    `open http://localhost:4567`

    # Wait for the thread to stop
    t.join
  end
end

task :default => :console
