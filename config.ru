require 'rubygems'
require 'bundler'
require 'sinatra'
require 'data_mapper'

Bundler.require

require './app.rb'
run Sinatra::Application