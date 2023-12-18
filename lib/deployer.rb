require 'fileutils'
require 'yaml'

module Zarkiel
    module Shugo
        class Deployer

            def initialize
                raise StandardError.new "No config found" if !File.exists? "config.yml"
                @config = YAML.load_file("config.yml")
                @repositories = @config["repositories"]
            end

            def build_command(command)
                command = command.prepend("sudo ") if @config["sudo"]
                command
            end

            def clean(path)
                FileUtils.rm_rf path if File.exists? path
            end

            def make_deploy_path(path)
                user = ENV["USER"]
                if !File.exists? path
                    system build_command("mkdir #{path}")
                end
                system(build_command("chown -R #{user}:#{user} #{path}")) if @config["sudo"]
            end

            def rollback_permissions(path)
                system(build_command("chown -R root:root #{path}")) if @config["sudo"]
            end

            def make_tmp_path
                FileUtils.mkdir "./tmp" if !File.exists? "./tmp"
            end

            def extract_files(tmp_path, deploy_path, branch)
                if File.exists? tmp_path
                    system build_command("git --git-dir=#{tmp_path} --work-tree=#{deploy_path} checkout #{branch} .")
                end
            end

            def clone_repository(url, name)
                system "git clone --bare #{url} ./tmp/#{name}"
            end

            def run_after(deploy_path)
                if File.exists? "#{deploy_path}/composer.json"
                    system("
                        cd #{deploy_path}
                        composer install
                    ")
                end
            end

            def deploy_repository(full_name)
                if @repositories.key? full_name
                    name = full_name.split("/")[1]

                    tmp_path = "./tmp/#{name}"
                    make_tmp_path
                    clean(tmp_path)

                    clone_url = @repositories[full_name]["clone_url"]
                    deploy_path = @repositories[full_name]["path"]
                    branch = @repositories[full_name]["branch"]

                    make_deploy_path(deploy_path)
                    clone_repository(clone_url, name)
                    extract_files(tmp_path, deploy_path, branch)
                    run_after(deploy_path)
                    rollback_permissions(deploy_path)
                    clean(tmp_path)
                end
            end

            def deploy_all
                @repositories.each do |full_name, repository|
                    deploy_repository(full_name)
                end
            end
        end
    end
end