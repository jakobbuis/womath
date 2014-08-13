require 'json'
require 'unirest'
require './config.rb'

Unirest.default_header 'X-Mashape-Key', $config[:mashape][:api_key]
response = Unirest.get("https://nametoolkit-name-toolkit.p.mashape.com/v1/whois?q=#{ARGV[0]}")

puts "HTTP error: #{response.code}" unless response.code == 200
puts JSON.pretty_generate response.body
