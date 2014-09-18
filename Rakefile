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
    require './test/trepscore-services-web'
    TrepScoreServicesWeb.run!
  end
end

task :default => :console
