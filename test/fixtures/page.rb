class Page < ActiveRecord::Base
  validates_presence_of :title
  
  suggests_id :target => :url, 
              :disposable => ['class', 'preparatory', 'prep', 'school', 'high', 'junior', 'middle', 'elementary'],
              :suffix => '-0000',
              :suffix_iterations => 20
end