module Impasse
  class ImpasseTSEHist < ActiveRecord::Base
    unloadable
  
    set_table_name "impasse_t_s_e_hists"
  
    belongs_to :test_steps
    belongs_to :execution_histories
    belongs_to :executions
    belongs_to :author, class_name: "User", foreign_key: "author_id"
    belongs_to :project
    # attr_accessible :title, :body
  
    validates :project, :author, :execution_histories, :test_steps, presence: true
  
  end
end 
