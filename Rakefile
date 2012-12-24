# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "simplecov-jscoverage"
  gem.homepage = "http://github.com/yard/simplecov-jscoverage"
  gem.license = "MIT"
  gem.summary = %Q{jscoverage reports to simplecov gem}
  gem.description = %Q{This gem aims to provide a drop-and-forget Javascript coverage reporting to simplecov by instrumenting files going through Assets Pipeline and carefully harvesting the results from a headless browser/Selenium/whatever.}
  gem.email = "mail2lf@gmail.com"
  gem.authors = ["Anton Zhuravsky"]
  # dependencies defined in Gemfile
  gem.add_dependency "rails", ">= 3.1.0"
  gem.add_dependency "simplecov"
  gem.add_dependency "tilt"
  gem.add_dependency "capybara"
  gem.add_dependency "poltergeist"
end
Jeweler::RubygemsDotOrgTasks.new
