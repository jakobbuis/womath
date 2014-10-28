require './config.rb'
require 'json'
require 'oauth'

class LinkedIn

    def initialize
        consumer = OAuth::Consumer.new($config[:linkedin][:api_key], $config[:linkedin][:api_secret], {site: 'https://api.linkedin.com'})
        @linkedin = OAuth::AccessToken.new(consumer, $config[:linkedin][:user_token], $config[:linkedin][:user_secret])
    end

    def name
        :linkedin
    end

    def execute domain
        response = @linkedin.get("http://api.linkedin.com/v1/companies?email-domain=#{domain}&format=json")
        return nil unless response.code == '200'

        companies = JSON.parse(response.body)['values']

        # Return all names
        companies.inject [] { |array, company| array << company['name'] }
    end
end
