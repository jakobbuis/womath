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
        Person.update_all company_identifier: nil, company_name: nil

        Person.find_each do |person|
            # Only proceed if we have an e-mail address we can parse
            next unless /.*@.+\..+/.match person.email

            # Extract domain
            domain = /.*@(.*)/.match(person.email)[1]

            # Do not process IP addresses
            next if /^[0-9\.]+$/.match domain

            # Do not process e-mails addresses from provider (e.g. @gmail.com, @hotmail.com)
            next if @known_email_providers.include? domain

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
        end
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
