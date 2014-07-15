require 'active_record'
require './config.rb'

# Establish database connection
ActiveRecord::Base.establish_connection(
  adapter:  'mysql2',
  database: $config[:database][:database],
  host:     'localhost',
  username: $config[:database][:user],
  password: $config[:database][:password],
)
