require 'bundler/setup'
require 'httparty'
require './config.rb'
require './database.rb'
require './models/person.rb'

# Basic class for consuming the API
class IgnoreLowContributions
    include HTTParty
    base_uri 'https://api.github.com'
    headers 'Accept' => 'application/vnd.github.v3+json', 'User-Agent' => 'jakobbuis/womath'

    def initialize(options)
        @config = options
    end

    def execute!
        # Iterate over all entries
            # Call github to get their contribution to the repo
            # mark as ignored if under threshold
            # persist
    end

    private

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
instructions = "Usage: ruby IgnoreLowContributions.rb [-v]\n"
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
    verbose: (ARGV[1].present? and ARGV[1] == '-v')
}

# Boot the main process
IgnoreLowContributions.new(options).execute!
