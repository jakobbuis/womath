require 'bundler/setup'
require './DetermineCompany.rb'

# Show help text
if ARGV[0].present? and (ARGV[0] == '-h' or ARGV[0] == '--help')
    puts "Usage: ruby determine_company.rb [-v]"
    exit 0
end

# Construct main process
options = {
    verbose: (ARGV[0].present? and ARGV[0] == '-v'),
    known_email_providers: JSON.parse(File.read('known_email_providers.json'))
}

# Boot the main process
DetermineCompany.new(options).execute
