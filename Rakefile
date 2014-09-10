require 'rubygems'
require 'bundler/setup'

task :console do
  require 'pry'
  require 'trepscore'
  TrepScore::Services.load

  ARGV.clear
  Pry.start
end

task :default => :console
