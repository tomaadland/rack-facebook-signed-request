$LOAD_PATH.unshift File.dirname(__FILE__) + '/../'
require "sinatra/base"

class SampleApp < Sinatra::Base
  set :environment, 'test'
 end
