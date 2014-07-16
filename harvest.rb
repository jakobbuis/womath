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
        url = "https://api.github.com/repos/#{user}/#{repository}/contributors?anon=false"

        # Grab all contributors
        contributors = self.class.get(url).each do |contributor|
            Person.create({ repository: "#{user}/#{repository}", username: contributor["login"] })
        end
        puts "Retrieved #{contributors.length} contributors"

        
        # unless ARGV.include?('--skip-eclipse-repositories')
        #     # Find the Eclipse foundation
        #     eclipse = self.class.get('https://api.github.com/orgs/eclipse', @config)

        #     # Grab each Eclipse repository and store it
        #     grab eclipse['repos_url'] do |repository|
        #         store_repository repository
        #     end
        # end

        # unless ARGV.include?('--skip-contributors')
        #     # Gather the contributors of every repository
        #     puts "Debug: now getting contributors"
        #     Repository.all.each do |repository|
        #         # Note: normally, one would call the repository details page (e.g. api.github.com/repos/123)
        #         # to find the the contributors_url, but that takes an extra request against our rate limit
        #         # As this study is limited in scope (regarding time), we assume the GitHub API doesn't change
        #         self.class.get("#{repository.url}/contributors", @config).each do |c|
        #             contributor = store_contributor c
        #             store_work(contributor, repository) if contributor && repository
        #         end
        #     end
        # end

        # unless ARGV.include?('--skip-contributor-repositories')
        #     # Grab all repositories of every contributor
        #     Contributor.all.each do |contributor|
        #         grab "#{contributor['url']}/repos" do |r|
        #             repository = store_repository r
        #             store_work(contributor, repository) if contributor && repository
        #         end
        #     end        
        # end
    end

    private 

    # # Utility function to deal with pagination
    # def grab (url, &block)
    #     page = 1
    #     results = []
    #     while true
    #         puts "Debug: now on #{url} page ##{page}"

    #         # Grab a page of repositories
    #         response = self.class.get(url+'?per_page=100&page='+page.to_s, @config)

    #         # Apply the callback to each elements
    #         response.each do |r|
    #             block.call(r)
    #         end

    #         # Stop if we are at the end of the list
    #         break if response.count < 100
            
    #         # else continue
    #         page += 1
    #     end
    # end

    # # Utility function that stores the relevant data of a repository automatically
    # def store_repository data
    #     repository = Repository.find_or_initialize_by(github_id: data['id'])
    #     repository.update_attributes({
    #         github_id: data['id'],
    #         url: data['url'],
    #         name: data['full_name'],
    #         description: data['description'],
    #     })
    #     repository
    # end

    # # Utility function that stores the relevant data of a contributor automatically
    # def store_contributor data
    #     return nil unless data['id'].present? and data['url'].present?

    #     contributor = Contributor.find_or_initialize_by(github_id: data['id'])
    #     contributor.update_attributes({
    #         github_id: data['id'],
    #         url: data['url'],
    #     })
    #     contributor
    # end

    # # Utility functions that stores the relationship between a contributor and a repository
    # def store_work contributor, repository
    #     # Do not save if the association exists already
    #     return if repository.contributors.where(id: contributor.id).exists?

    #     # Store otherwise
    #     repository.contributors << contributor
    #     repository.save
    # end

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
