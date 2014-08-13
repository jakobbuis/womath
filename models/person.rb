require 'active_record'

class Person < ActiveRecord::Base
    def self.classified
        where.not company_name: nil
    end
end
