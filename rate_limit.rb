require 'bundler/setup'
require 'httparty'
require './config.rb'

response = HTTParty.get('https://api.github.com/rate_limit', basic_auth: {username: $config[:github][:user], password: $config[:github][:password]}, headers: {'User-Agent' => 'jakobbuis/darkharvest'})
puts 'Remaining queries: ' + response['resources']['core']['remaining'].to_s + '/' + response['resources']['core']['limit'].to_s
puts 'Reset time: ' + DateTime.strptime(response['resources']['core']['reset'].to_s, '%s').to_s
