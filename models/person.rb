require 'active_record'

class Person < ActiveRecord::Base
    def self.classified
        where.not company_name: nil
    end

    def self.unclassified
        where company_name: nil
    end
end
