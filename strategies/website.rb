require 'timeout'
require 'nokogiri'
require 'open_uri_redirections'

class Website

    def name
        :website
    end

    def execute domain
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
        name
    end

    private 

    def grab_webpage address
        begin
            Timeout::timeout 10 do
                # Attempt to download the website
                website = Nokogiri::HTML(open("http://#{address}", allow_redirections: :safe))

                # Grab consecutive capitalised words in the title of the page
                title = /([A-Z][\w-]*(\s+[A-Z][\w-]*)+)/.match(website.search('title').text)
                return title[0][0..40].strip if title
            end
        rescue Exception
        end
        nil
    end

end
