module Impasse
  class Execution < ActiveRecord::Base
    unloadable
    self.table_name = "impasse_executions"
    self.include_root_in_json = false
 
    attr_accessible :id, :status, :notes, :test_plan_case_id, :tester_id, :custom_field_values

    belongs_to :test_plan_case
    has_many :issues, :through => :execution_bugs
    has_many :execution_bugs

    acts_as_customizable
  end
end
