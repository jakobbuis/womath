require 'json'
require './config.rb'
require 'oauth'
 
# Fill the keys and secrets you retrieved after registering your app
api_key = $config[:linkedin][:api_key]
api_secret = $config[:linkedin][:api_secret]
user_token = $config[:linkedin][:user_token]
user_secret = $config[:linkedin][:user_secret]
 
# Specify LinkedIn API endpoint
configuration = { :site => 'https://api.linkedin.com' }
 
# Use your API key and secret to instantiate consumer object
consumer = OAuth::Consumer.new(api_key, api_secret, configuration)
 
# Use your developer token and secret to instantiate access token object
access_token = OAuth::AccessToken.new(consumer, user_token, user_secret)
 
# Make call to LinkedIn to retrieve your own profile
response = access_token.get("http://api.linkedin.com/v1/companies?email-domain=#{ARGV[0]}&format=json")
unless response.code == '200'
    puts "HTTP error: #{response.code}"
    exit
end
body = JSON.parse(response.body)
puts JSON.pretty_generate(body)
