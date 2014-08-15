require 'public_suffix'

class Domain

    def name
        :domain
    end

    def execute domain
        PublicSuffix.parse(domain).sld.capitalize
    end
end
