require 'yaml'
require 'openssl'
require 'http'
require 'json'
require File.expand_path("deployer", File.dirname(__FILE__))

module Zarkiel
    module Shugo
        class RequestHandler
            def initialize(request)
                raise StandardError.new "No config found" if !File.exists? "config.yml"
                @config = YAML.load_file("config.yml")
                
                @request = request
                @body = request.body.read
                @data = JSON.parse(@body)
                @deployer = Deployer.new

            end

            def authorize
                key = ENV["key"] || ""
                signature = @request.env["HTTP_X_GITEA_SIGNATURE"]
                local_signature = OpenSSL::HMAC.hexdigest("SHA256", key, @body)
                raise StandardError.new "Invalid Request" if signature != local_signature
            end

            def deliver
                authorize
                if !@data["repository"].nil? && !@data["repository"]["name"].nil?
                    repository = @data["repository"]
                    @deployer.deploy_repository(repository["full_name"])
                end
            end

            def relay
                unless @config["relay"].nil?
                    @config["relay"].each do |relay_url|
                        HTTP.post(relay_url, body: @body, headers: {
                            "X-Gitea-Signature" => @request.env["HTTP_X_GITEA_SIGNATURE"]
                        })
                    end
                end
            end

            
        end
    end
end