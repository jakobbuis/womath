# Classifier for eclipse projects
require 'bundler/setup'
require 'httparty'
require './config.rb'
require './database.rb'
require './models/contributor.rb'
require './models/repository.rb'

print 'Counting words...'

counts = Hash.new(0)

Repository.unknown.each do |repo|
    # Count name words
    name = repo.name.split('/')
    counts[name[1]] += 1

    # Count description words
    next if repo.description.nil?
    repo.description.split(' ').each do |word|
        next if word.length < 3
        counts[word] += 1
    end
end

puts 'done'

puts "Found #{counts.count} words"
puts 'Top 100 keywords:'

counts = counts.sort_by { |word, count| -count }

i = 100

counts.each do |entry|
    # Output word
    puts "#{entry[0]} (#{entry[1]})"


    # Countdown
    i -= 1
    break if i < 1
end