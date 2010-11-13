class Word  
  include Comparable
  include Mongoid::Document
  field :phrase
  field :searches, :type => Integer
  key :phrase
  validates_presence_of :phrase
  validates_uniqueness_of :phrase
  attr_accessible :phrase, :searches
  embedded_in :users, :inverse_of => :words
  
  def to_s
    "#{id}"
  end
  
  # sort a list of Words by highest to lowest number of searches
  def <=>(other)
    if self.searches < other.searches
      1
    elsif self.searches > other.searches
      -1
    else
      0
    end
  end

end