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

    def initialize(user, pass)
        @config = {basic_auth: {username: user, password: pass}}
    end

    # Gather all repositories from GitHub
    # and store them in the local database
    def execute!
        # Validate input parameters
        if ARGV[0].nil?
            raise 'Missing repository name as parameter; use as "ruby harvest.rb jakobbuis/womath"'
        end

        # Build useful variables
        user, repository = ARGV[0].split('/')

        # Grab all contributors
        i = 0
        grab "https://api.github.com/repos/#{user}/#{repository}/commits" do |commit|
            email = commit['commit']['author']['email']

            # Skip all anonymous entries
            next if /@users.noreply.github.com$/ =~ email
            
            Person.find_or_create_by(repository: repository, email: email)
            i += 1
        end

        # Report success
        puts "Done. Grabbed #{i} relevant commits"
    end

    private
        
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

# Execute the main research process
GitHub.new($config[:github][:user], $config[:github][:password]).execute!
