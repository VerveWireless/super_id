# Require dummy app
ENV["RAILS_ENV"] = "test"
require File.expand_path("../../spec/dummy/config/environment.rb",  __FILE__)

# Require binding.pry
require 'pry'
require 'pry-nav'