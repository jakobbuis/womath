# Sinatra endpoint for the AMT API callback
require 'json'
require 'sinatra'
require './database'
require './models/repository.rb'
require './models/contributor.rb'

# Show main interface
get '/classified/:count' do |count|
    @repositories = Repository.known.not_duplicate.random(count)
    erb :validation
end

get '/unknown' do
    @repositories = Repository.unknown
    erb :validation
end

get '/results' do
    @contributors = Contributor.multihomers
    erb :results
end

get '/combination' do
    contributors = Contributor.multihomers
    @combinations = []
    contributors.each do |c| 
        c.repositories.of_interest.each do |r1| 
            c.repositories.of_interest.each do |r2| 
                unless r1.id == r2.id # Reject if a circle 
                    unless @combinations.include?({id1: r2.id, id2: r1.id}) # Reject if the other way around is already present
                        @combinations << {id1: r1.id, id2: r2.id}
                    end
                end 
            end 
        end  
    end  
    erb :combination
end