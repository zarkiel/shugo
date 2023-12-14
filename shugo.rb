require 'fileutils'
require 'yaml'
require 'openssl'

module Zarkiel
    class Shugo
        def initialize(request)
            raise StandardError.new "No config found" if !File.exists? "config.yml"
            @request = request
            @body = request.body.read
            @repositories = YAML.load_file("config.yml")["repositories"]
            @data = JSON.parse(@body)
        end

        def clean(path)
            FileUtils.rm_rf path if File.exists? path
        end

        def make_deploy_path(path)
            user = ENV["USER"]
            if !File.exists? path
                system "sudo mkdir #{path}"
                system "sudo chown -R #{user}:#{user} #{path}"
            end
        end

        def make_tmp_path
            FileUtils.mkdir "./tmp" if !File.exists? "./tmp"
        end

        def deploy(tmp_path, deploy_path, branch)
            if File.exists? tmp_path
                system "git --git-dir=#{tmp_path} --work-tree=#{deploy_path} checkout #{branch} ."  
             end
        end

        def authorize
            key = ENV["key"] || ""
            signature = @request.env["HTTP_X_GITEA_SIGNATURE"]
            local_signature = OpenSSL::HMAC.hexdigest("SHA256", key, @body)
            raise StandardError.new "Invalid Request" if signature != local_signature
        end

        def clone_repository(url, name)
            system("
                    cd ./tmp
                    git clone --bare #{url} #{name}
                ")
        end

        def deliver
            authorize

            if !@data["repository"].nil? && !@data["repository"]["name"].nil?
                repository = @data["repository"]
                clone_url = repository["clone_url"]
                name = repository["name"]
                tmp_path = "./tmp/#{name}"
                
                make_tmp_path
                clean tmp_path
                
                if @repositories.key? repository["full_name"]
                    deploy_path = @repositories[repository["full_name"]]["path"]
                    branch = @repositories[repository["full_name"]]["branch"]
                    
                    make_deploy_path(deploy_path)
                    clone_repository(clone_url, name)
                    deploy(tmp_path, deploy_path, branch)
                    run_after(deploy_path)
                    clean(tmp_path)
                end
            end

            return ""
        end

        def run_after(deploy_path)
            if File.exists? "#{deploy_path}/composer.json"
                system("
                    cd #{deploy_path}
                    composer install
                ")
            end
        end

    end
end