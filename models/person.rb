require 'active_record'

class Person < ActiveRecord::Base
    def self.classified
        where.not company_identifier: nil
    end
end
