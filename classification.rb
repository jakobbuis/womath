# Classifier for eclipse projects
require 'bundler/setup'
require 'httparty'
require './config.rb'
require './database.rb'
require './models/contributor.rb'
require './models/repository.rb'

print 'Reset classification...'
# Reset classification so that each iteration stands on its own
Repository.update_all(classification: nil)
puts 'done'

print 'Classifying...'

# Ecosystem/keyword index
# Less specific keywords go to the back
ecosystems = {
    # Removes entries which are a duplicate of other repositories
    duplicate: [:mirror, :clone, :fork],

    # Eclipse projects
    eclipse: [:eclipse, :mylyn, :orion],

    # Editors
    sublime: [:sublime, :emmet],
    visualstudio: ['visual studio'],
    vim: [:vim],
    aptana: [:aptana],
    intellij: [:intellij],
    textmate: [:textmate],

    # # Tech organisations
    # google: [:android, :google, :chrome],
    # apple: [:apple, :ios, :mac, :iphone, :ipod, :osx, 'OS X'],
    # apache: [:apache, :tomcat, :maven],
    # mozilla: [:mozilla, :firefox, :thunderbird, :bugzilla, :firebug, :gecko],
    # microsoft: [:microsoft, :windows, :office, :word, :powerpoint, :excel, :msn, :visio, :outlook, :onenote, :access, :infopath, :publisher, :lync, :frontpage, :sharepoint],
    # amazon: [:amazon],

    # # Code ecosystems
    # ruby: [:ruby, :rails, :rspec, :sinatra, :nokogiri, :rake, :redmine, :rack, :jekyll, :minitest],
    # node: [:node, :npm],
    # javascript: [:javascript, :jquery, :ember, :angular, :kendo, :backbone, :handlebars, :mustache, :greasemonkey, :js, :coffeescript, :grunt, :yeoman],
    # erlang: [:erlang, :otp],
    # css: [:css, :less, :scss],
    # unix: [:unix, :gnu],
    # java: [:java, :spring, :scala, :play, :jvm],
    # django: [:django],
    # php: [:php, :cakephp, :kohana, :laravel, :zend, :yii, :codeigniter, :symfony, :prado, :akelos, :phpdevshell],
    # python: [:pytjon, :pycon],
    # clojure: [:clojure],
    
    # # Other ecosystems
    # linux: [:linux, :ubuntu, :redhat, :gnome, :suse, :fedora, :jboss],
    # social: [:twitter, :facebook, :linkedin, :pinterest, 'google plus', :tumblr, :instagram, :flickr, :myspace, :askfm, 'ask.fm', :meetup, :meetme, :classmates],
    # sysadmin: [:chef, :cookbook, :puppet, :jenkins, :cruisecontrol, :capistrano, :teamcity, :hudson],
    # compiler: [:compiler],
    # git: [:git],
    # databases: [:sql, :nosql, :riak, :voldemort, :hadoop, :hbase, :cassandra, :mongodb, :couchbase, :couchdb, :azure, :redis, :memcache, :neo4j],

    # Empty placeholder for unclassified repositories; do not add any keywords
    unknown: []
}

# Classify based on the name of the repository
ecosystems.each do |name, keywords|
    keywords.each do |keyword|
        Repository.where("name LIKE '%#{keyword}%'").update_all(classification: name)
    end
end

# Classify remaining repository based on description
ecosystems.each do |name, keywords|
    keywords.each do |keyword|
        Repository.where(classification: nil).where("description LIKE '%#{keyword}%'").update_all(classification: name)
    end
end

# Everything else is 'unknown' 
Repository.where(classification: nil).update_all(classification: :unknown)

puts 'done'

# Print informational statistics
stats = {}
ecosystems.each do |name, keywords|
    stats[name] = Repository.where(classification: name).count
end
total = Repository.count

puts "Classification finished:"
stats.each do |name, count|
    puts "#{name}: #{count}/#{total} (#{((count.to_f/total.to_f)*100).round(2)}%)"
end
