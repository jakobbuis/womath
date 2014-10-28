require 'bundler/setup'
require './config.rb'
require './database.rb'
require './models/person.rb'
require 'public_suffix'
require 'levenshtein'

require './strategies/linkedin.rb'
require './strategies/whois.rb'
require './strategies/website.rb'
require './strategies/domain.rb'

# Basic class for consuming the API
class DetermineCompany

    def initialize options
        @verbose = options[:verbose]
        @known_email_providers = options[:known_email_providers]
    end

    def execute
        clean_previous_results!

        puts "Starting classification..." if @verbose
        Person.find_each do |person|

            next unless valid? person

            # Extract domain
            domain = /.*@(.*)/.match(person.email)[1]
            root_domain = PublicSuffix.parse(domain).domain

            # Execute all strategies
            strategies = [LinkedIn.new, Whois.new, Website.new, Domain.new]
            results = strategies.map { |s| s.execute domain }
            results.flatten!

            # Purge all strategies which could not give a solid answer
            results.reject! &:blank?

            # Skip if there's no answer
            next if results.count == 0

            # If we have only one valid answer, take that one (obviously)
            if results.count == 1
                accept person, results[0]
                next
            end

            # Merge identical names with weights, merging substrings too
            # i.e. ["Microsoft", "Microsoft India", "IBM", "Microsoft"] becomes {"Microsoft" => 3, "IBM" => 1}
            # this algorithm also captures typos and very near misses with a levenshtein distance < 3
            results.sort_by! &:length
            names = Hash.new(0)
            results.each do |r|
                desired_key = r
                names.each do |name, weight|
                    if r.include? name or Levenshtein.distance(r, name) < 3
                        desired_key = name
                        break
                    end
                end
                names[desired_key] = names[desired_key] + 1
            end

            # Accept the answer with the largest weight
            accept person, names.max_by { |name, weight| weight }[0]
        end

        # Report success
        puts "Classification finished. #{Person.classified.count}/#{Person.count} successful (#{(Person.classified.count.to_f/Person.count.to_f*100).round}%)" if @verbose
    end

    private

    def clean_previous_results!
        print "Clearing previous sessions..." if @verbose
        Person.update_all company_name: nil, status_code: nil
        puts 'done' if @verbose
    end

    def valid? person
        # Only proceed if we have an e-mail address we can parse
        unless /.*@.+\..+/.match person.email
            reject(person, :email_format_invalid, 'not a parseable e-mail address')
            return false
        end

        # Extract domain
        domain = /.*@(.*)/.match(person.email)[1]

        # Do not process IP addresses
        if /^[0-9\.]+$/.match domain
            reject(person, :domain_IP_address, 'is an IP-address')
            return false
        end

        # Determine the domain root based on the list of public suffixes
        begin
            root_domain = PublicSuffix.parse(domain).domain
        rescue PublicSuffix::DomainInvalid
            reject(person, :invalid_TLD, 'invalid TLD')
            return false
        end

        # Do not process e-mails addresses from known providers (e.g. @gmail.com, @hotmail.com)
        if @known_email_providers.include? root_domain
            reject(person, :known_email_provider, 'is a known e-mail provider')
            return false
        end

        true
    end

    def accept person, company_name
        # Always truncate to match max field length (45)
        company_name = company_name[0..40]

        # Write to database
        person.update_attribute :company_name, company_name

        # Output result
        puts "#{person.email} works at #{company_name}" if @verbose
    end

    def reject person, error_code, message
        person.update_attribute 'status_code', error_code
        puts "#{person.email} rejected: #{message} (#{error_code})" if @verbose
    end
end