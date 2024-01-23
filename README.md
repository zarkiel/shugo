## Shugo Auto Deployment

This tool will help you to automate deployments by using Web Hooks

## Requirements
- Ruby 3.0+

Install required gems

`bundle install`

## Configuration

Check *config.yml.example* in order to create your own custom *config.yml* file.

    sudo: true # Set true if the current user will need sudo permissions
    relay:
        - http://another-server/deploy # Relay web hook to another server
    repositories:
        user/repository:
            path: "/path-to-deploy" 
            clone_url: "http://clone_url"
            branch: "master"
## Usage 

Deploy all configured repositories

    ./shugo setup
Start deployment server

    key=<SECRET_KEY> ./shugo server


