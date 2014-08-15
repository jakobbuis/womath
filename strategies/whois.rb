require 'unirest'
require './config.rb'

class Whois

    def initialize
        Unirest.default_header 'X-Mashape-Key', $config[:mashape][:api_key]
    end

    def name
        :whois
    end

    def execute domain
        # Grab WHOIS information from commercial API
        response = Unirest.get("https://nametoolkit-name-toolkit.p.mashape.com/v1/whois?q=#{domain}")
        return nil unless response.code == 200

        # Determine which field to use
        if response.body['registrant'] and response.body['registrant']['organization']
            return response.body['registrant']['organization']
        elsif response.body['administrative_contact'] and response.body['administrative_contact']['organization']
            return response.body['administrative_contact']['organization']
        else
            return nil
        end
    end
end
