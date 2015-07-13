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
        People.where.not(company_name: nil)  do |person|
            print "\"#{person.name}\", \"#{getContribution(person)}\"\n"
        end
    end

    private

    def getContribution person
        page = 1
        results = []
        commits = 0
        while true
            # Grab a page of repositories
            response = self.class.get("https://api.github.com/repos/eclipse/#{person.repository}/commits?per_page=100&page=#{page.to_s}", @config)

            # Do not capture repositories that return HTTP errors (empty repositories do this)
            break if response.code >= 400

            # Apply the callback to each elements
            commits = commits + response.count

            # Stop if we are at the end of the list
            break if response.count < 100

            # else continue
            page += 1
        end

        return commits
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
instructions = "Usage: ruby GetContributionCounts.rb [-v]\n"
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
