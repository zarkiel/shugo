require 'sinatra'
require 'json'
require './shugo'

set :default_content_type, :json

post '/' do
    shugo = Zarkiel::Sugo.new(request)
    shugo.deliver
end