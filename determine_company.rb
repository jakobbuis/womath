require 'bundler/setup'
require 'nokogiri'
require 'open-uri'
require './config.rb'
require './database.rb'
require './models/person.rb'
require 'open_uri_redirections'
require 'timeout'

# Basic class for consuming the API
class DetermineCompany

    def initialize(verbose, known_email_providers)
        @verbose = verbose
        @known_email_providers = known_email_providers
        @domain_name_cache = {}
    end

    def execute!
        # Start with a clean slate
        print "Clearing all company_identifier and company_name fields..." if @verbose
        Person.update_all company_identifier: nil, company_name: nil
        puts 'done' if @verbose

        puts "Starting classification..." if @verbose
        Person.find_each do |person|
            print "Processing #{person.email}..." if @verbose

            # Only proceed if we have an e-mail address we can parse
            unless /.*@.+\..+/.match person.email
                puts "rejected: not a parseable e-mail address" if @verbose
                next
            end

            # Extract domain
            domain = /.*@(.*)/.match(person.email)[1]

            # Do not process IP addresses
            if /^[0-9\.]+$/.match domain
                puts "rejected: is an IP-address" if @verbose
                next
            end

            # Do not process e-mails addresses from provider (e.g. @gmail.com, @hotmail.com)
            if @known_email_providers.include? domain
                puts "rejected: is a known e-mail provider" if @verbose
                next
            end

            # Extract most-significant domain part
            # 1) If the domain is two parts long, choose the first
            # 2) If the domain is three parts or longer and the second part is two characters, choose the first
            # 3) If the domain is three parts or longer, choose the second to last part 
            parts = domain.split('.')
            parts.pop # Remove the last part
            if parts.length == 1
                company_identifier = parts[0]
            else
                company_identifier = parts.pop
                company_identifier = parts.pop if company_identifier.length == 2
            end

            # Find the company on their website
            company_name = find_company_name_on domain
            if !company_name
                company_name = company_identifier.capitalize 
            end

            # Save results
            person.update_attributes company_identifier: company_identifier, company_name: company_name
            puts "works at #{company_name}"
        end
        puts "Classification finished. #{Person.classified.count}/#{Person.count} successful (#{(Person.classified.count.to_f/Person.count.to_f*100).round}%)" if @verbose
    end

    private

    def find_company_name_on domain
        return @domain_name_cache[domain] if @domain_name_cache.include? domain
        
        name = grab_webpage domain

        unless name
            # Keep trying shorter domain names until you find a name or run out of domain names
            until domain.split('.').length == 1 || name.present?
                domain_parts = domain.split('.')
                domain_parts.shift
                domain = domain_parts.join('.')
                name = grab_webpage domain
            end
        end

        # Store in cache to avoid future double calls
        @domain_name_cache[domain] = name
        
        return name
    end

    def grab_webpage domain
        begin
            Timeout::timeout 10 do
                # Attempt to download the website
                website = Nokogiri::HTML(open("http://#{domain}", allow_redirections: :safe))

                # Grab consecutive capitalised words in the title of the page
                title = /([A-Z][\w-]*(\s+[A-Z][\w-]*)+)/.match(website.search('title').text)
                return title[0][0..45] if title
            end
        rescue Exception
        end

        return nil
    end
end

# Validate input parameters
instructions = "Usage: ruby determine_company.rb [-v]"
if ARGV[0] == '-h' or ARGV[0] == '--help'
    puts instructions
    exit 1
end

# Process the options given
verbose = (ARGV[0].present? and ARGV[0] == '-v')

known_email_providers = JSON.parse(File.read('known_email_providers.json'))

# Boot the main process
DetermineCompany.new(verbose, known_email_providers).execute!
