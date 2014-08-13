require 'bundler/setup'
require 'nokogiri'
require 'open-uri'
require './config.rb'
require './database.rb'
require './models/person.rb'
require 'open_uri_redirections'
require 'timeout'
require 'unirest'
require 'oauth'

# Basic class for consuming the API
class DetermineCompany

    def initialize(verbose, known_email_providers, mashape_api_key)
        @verbose = verbose
        @known_email_providers = known_email_providers

        Unirest.default_header 'X-Mashape-Key', mashape_api_key

        @cache = {
            email: {},
            website: {},
            whois: {},
            linkedin: {},
        }

        # Instantiate OAuth consumer for LinkedIn
        consumer = OAuth::Consumer.new($config[:linkedin][:api_key], $config[:linkedin][:api_secret], {site: 'https://api.linkedin.com'})
        @linkedin = OAuth::AccessToken.new(consumer, $config[:linkedin][:user_token], $config[:linkedin][:user_secret])
    end

    def execute!
        # Start with a clean slate
        print "Clearing all company names..." if @verbose
        Person.update_all company_name: nil
        puts 'done' if @verbose

        puts "Starting classification..." if @verbose
        Person.find_each do |person|

            # Try to find it in the cache
            if @cache[:email].include? person.email
                store_result(person, @cache[:email][person.email])
                next
            end

            # Only proceed if we have an e-mail address we can parse
            unless /.*@.+\..+/.match person.email
                reject(person, 'not a parseable e-mail address')
                next
            end

            # Extract domain
            domain = /.*@(.*)/.match(person.email)[1]

            # Do not process IP addresses
            if /^[0-9\.]+$/.match domain
                reject(person, 'is an IP-address')
                next
            end

            # Do not process e-mails addresses from known providers (e.g. @gmail.com, @hotmail.com)
            if @known_email_providers.include? domain
                reject(person, 'is a known e-mail provider')
                next
            end

            # Attempt: Use the LinkedIn-API to find the company name
            response = get_linkedin_for domain
            if response.code == '200'
                companies = JSON.parse(response.body)['values']
                # Use the shortest one (deals with things like ["Microsoft", "Microsoft India", "Microsoft France"])
                candidate_name = companies[0]['name']
                companies.each do |companies|
                    candidate_name = companies['name'] if companies['name'].length < candidate_name.length
                end

                store_result(person, candidate_name)
                next
            end

            # Attempt: Use a WHOIS API to find the company name
            response = get_whois_for domain
            if response.code == 200
                # Determine which field to use
                if response.body['registrant'] and response.body['registrant']['organization']
                    company_name = response.body['registrant']['organization']
                elsif response.body['administrative_contact'] and response.body['administrative_contact']['organization']
                    company_name = response.body['administrative_contact']['organization']
                end

                # Store result if successful
                if company_name
                    store_result(person, company_name)
                    next
                end
            end

            # Attempt: find the company name on their website
            company_name = find_company_name_on domain
            if company_name
                store_result(person, company_name)
                next
            end
            
            # Attempt: extract most-significant domain part and capitalize
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
            store_result(person, company_identifier.capitalize)
            next
        end

        # Report success
        puts "Classification finished. #{Person.classified.count}/#{Person.count} successful (#{(Person.classified.count.to_f/Person.count.to_f*100).round}%)" if @verbose
    end

    private

    def store_result person, name
        # Always truncate to match max field length (45)
        name = name[0..40]

        # Write to cache
        @cache[:email][person.email] = name

        # Write to database
        person.update_attribute 'company_name', name

        # Output result
        puts "#{person.email} works at #{name}" if @verbose
    end

    def reject person, message
        puts "#{person.email} rejected: #{message}" if @verbose
    end

    def find_company_name_on domain
        return @cache[:website][domain] if @cache[:website].include? domain
        
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
        @cache[:website][domain] = name
        
        return name
    end

    def grab_webpage domain
        begin
            Timeout::timeout 10 do
                # Attempt to download the website
                website = Nokogiri::HTML(open("http://#{domain}", allow_redirections: :safe))

                # Grab consecutive capitalised words in the title of the page
                title = /([A-Z][\w-]*(\s+[A-Z][\w-]*)+)/.match(website.search('title').text)
                return title[0][0..40].strip if title
            end
        rescue Exception
        end

        return nil
    end

    def get_whois_for domain
        unless @cache[:whois].include? domain
            @cache[:whois][domain] = Unirest.get("https://nametoolkit-name-toolkit.p.mashape.com/v1/whois?q=#{domain}")
        end
        @cache[:whois][domain]
    end

    def get_linkedin_for domain
        unless @cache[:linkedin].include? domain
            @cache[:linkedin][domain] = @linkedin.get("http://api.linkedin.com/v1/companies?email-domain=#{domain}&format=json")
        end
        @cache[:linkedin][domain]
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
DetermineCompany.new(verbose, known_email_providers, $config[:mashape][:api_key]).execute!
