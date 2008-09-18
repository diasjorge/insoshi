class Category < ActiveRecord::Base
  has_many :events, :dependent => :destroy

  validates_presence_of :name
end
