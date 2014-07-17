require 'bundler/setup'
require 'httparty'
require './config.rb'
require './database.rb'
require './models/person.rb'

# Basic class for consuming the API
class GitHub
    include HTTParty
    base_uri 'https://api.github.com'
    headers 'Accept' => 'application/json', 'User-Agent' => 'jakobbuis/womath'

    def initialize(options)
        @config = options
    end

    # Gather all repositories from GitHub
    # and store them in the local database
    def execute!
        if @config[:target][:repository].present?
            process_repository @config[:target][:owner], @config[:target][:repository], @config[:verbose]
        else 
            process_owner @config[:target][:owner], @config[:verbose]
        end
    end

    private

    def process_repository user, repository, verbose = false
        print "Processing #{user}/#{repository}..." if verbose

        i = 0
        grab "https://api.github.com/repos/#{user}/#{repository}/commits" do |commit|
            email = commit['commit']['author']['email']
            name = commit['commit']['author']['name']

            Person.find_or_create_by(repository: repository, email: email, name: name)
            i += 1
        end

        # Report success
        puts "done (#{i} commits)" if verbose
    end

    def process_owner user, verbose = false
        puts "Processing all repositories by #{user}.." if verbose

        # Grab all repositories
        grab "https://api.github.com/users/#{user}/repos" do |repository|
            process_repository user, repository['name'], verbose
        end

        puts "Finished processing #{user}. " if verbose
    end
        
    # Utility function to deal with pagination
    def grab (url, &block)
        page = 1
        results = []
        while true
            # Grab a page of repositories
            response = self.class.get(url+'?per_page=100&page='+page.to_s, @config)

            # Do not capture repositories that return HTTP errors (empty repositories do this)
            break if response.code >= 400

            # Apply the callback to each elements
            response.each do |r|
                block.call(r)
            end

            # Stop if we are at the end of the list
            break if response.count < 100
            
            # else continue
            page += 1
        end
    end

    # Override get method to take the rate limiter into account
    def self.get(*args, &block)
        result = super  # Execute the call to find the current rate limit
        if result.headers['x-ratelimit-remaining'].to_i < 10
            raise "Close to the rate limit (#{result.headers['x-ratelimit-remaining']}/#{result.headers['x-ratelimit-limit']})"
        end
        return result   # Return the original call
    end
end

# Validate input parameters
instructions = "Usage: ruby harvest.rb user[/repository] [-v]\n\nExamples:\n -ruby harvest.rb jakobbuis\n -ruby jakobbuis/womath -v"
if ARGV[0].nil? or ARGV[0] == '-h' or ARGV[0] == '--help'
    puts instructions
    exit 1
end

# Process the options given
options = {
    basic_auth: {
        username: $config[:github][:user],
        password: $config[:github][:password],
    },
    target: {
        owner: ARGV[0].split('/')[0],
        repository: ARGV[0].split('/')[1],
    },
    verbose: (ARGV[1].present? and ARGV[1] == '-v')
}

# Boot the main process
GitHub.new(options).execute!
