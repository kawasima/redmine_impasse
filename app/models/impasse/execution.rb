module Impasse
  class Execution < ActiveRecord::Base
    unloadable
    set_table_name "impasse_executions"
    self.include_root_in_json = false

    belongs_to :test_plan_case
    has_many :issues, :through => :execution_bugs
    has_many :execution_bugs

    acts_as_customizable
  end
end
