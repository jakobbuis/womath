require 'bundler/setup'
require './DetermineCompany.rb'

# Show help text
if ARGV[0].present? and (ARGV[0] == '-h' or ARGV[0] == '--help')
    puts "Usage: ruby determine_company.rb [-v] [-c] [-h]"
    puts "Arguments:"
    puts "-v: verbose console output"
    puts "-c: clean all existing entries before running"
    puts "-h: display this help text"
    exit 0
end

# Construct main process
options = {
    verbose: (ARGV.include? '-v'),
    clean_sweep: (ARGV.include? '-c'),
    known_email_providers: JSON.parse(File.read('known_email_providers.json'))
}

# Boot the main process
DetermineCompany.new(options).execute
