require 'active_record'

class Person < ActiveRecord::Base

    has_and_belongs_to_many :companies
end
