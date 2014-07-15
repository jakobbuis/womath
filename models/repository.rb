require 'active_record'

class Repository < ActiveRecord::Base

    has_and_belongs_to_many :contributors

    def self.random n = 100
        order('RAND()').limit(n)
    end

    def self.not_duplicate
        where.not(classification: :duplicate)
    end

    def self.known
        where.not(classification: :unknown)
    end

    def self.unknown
        where(classification: :unknown)
    end

    def self.of_interest
        where('classification NOT IN (?)', [:duplicate, :unknown]).order(:id)
    end
end
