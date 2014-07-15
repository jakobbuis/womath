require 'active_record'

class Contributor < ActiveRecord::Base

    has_and_belongs_to_many :repositories
end
