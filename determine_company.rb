require 'bundler/setup'
require 'nokogiri'
require './config.rb'
require './database.rb'
require './models/person.rb'

# Basic class for consuming the API
class DetermineCompany

    def initialize(verbose, known_email_providers)
        @verbose = verbose
        @known_email_providers = known_email_providers
    end

    def execute!
        # Start with a clean slate
        print "Clearing all company_identifier and company_name fields..." if @verbose
        Person.update_all company_identifier: nil, company_name: nil
        puts 'done' if @verbose

        puts "Starting classification..." if @verbose
        Person.find_each do |person|
            # Only proceed if we have an e-mail address we can parse
            unless /.*@.+\..+/.match person.email
                puts "Rejected #{person.email}: not a parseable e-mail address" if @verbose
                next
            end

            # Extract domain
            domain = /.*@(.*)/.match(person.email)[1]

            # Do not process IP addresses
            if /^[0-9\.]+$/.match domain
                puts "Rejected #{person.email}: is an IP-address" if @verbose
                next
            end

            # Do not process e-mails addresses from provider (e.g. @gmail.com, @hotmail.com)
            if @known_email_providers.include? domain
                puts "Rejected #{person.email}: is a known e-mail provider" if @verbose
                next
            end

            # Extract most-significant domain part
            # 1) If the domain is two parts long, choose the first
            # 2) If the domain is three parts or longer and the second part is two characters, choose the first
            # 3) If the domain is three parts or longer, choose the second to last part 
            parts = domain.split('.')
            parts.pop # Remove the last part

            if parts.length == 1
                ci = parts[0]
            else
                ci = parts.pop
                ci = parts.pop if ci.length == 2
            end

            person.update_attribute :company_identifier, ci
            puts "Classified #{person.email} as #{ci}"
        end
        puts "Classification finished. #{Person.classified.count}/#{Person.count} successful (#{(Person.classified.count.to_f/Person.count.to_f*100).round}%)" if @verbose
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
