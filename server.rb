require 'sinatra'
require 'json'
require './shugo'

set :default_content_type, :json

post '/' do
    shugo = Zarkiel::Shugo.new(request)
    shugo.deliver
    shugo.relay
end