require 'sinatra'
require 'json'
require './shugo'

set :default_content_type, :json
set :port, 4567

post '/' do
    begin
        shugo = Zarkiel::Shugo.new(request)
        shugo.deliver
        shugo.relay

        JSON.generate({status: "OK"})
    rescue => error
        JSON.generate({status: "ERROR", message: error.message})
    end    
end