require 'bundler/setup'
require 'httparty'
require './config.rb'
require './database.rb'
require './models/person.rb'
require 'net/http'
require 'uri'

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
        # Determine what to do
        user = @config[:target][:owner]
        repository = @config[:target][:repository]

        process_repository user, repository, @config[:verbose]
    end

    private

    def process_repository user, repository, verbose = false
        i = 0
        grab "https://api.github.com/repos/#{user}/#{repository}/commits" do |commit|
            email = commit['commit']['author']['email']
            name = commit['commit']['author']['name']

            # Skip all anonymous entries
            next if /@users.noreply.github.com$/ =~ email
            
            Person.find_or_create_by(repository: repository, email: email, name: name)
            i += 1
        end

        # Report success
        puts "Done. Grabbed #{i} relevant commits" if verbose
    end
        
    # Utility function to deal with pagination
    def grab (url, &block)
        page = 1
        results = []
        while true
            # Grab a page of repositories
            response = self.class.get(url+'?per_page=100&page='+page.to_s, @config)

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
if ARGV[0].nil?
    raise 'Missing repository name as parameter; use as "ruby harvest.rb jakobbuis/womath [-v]"'
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
