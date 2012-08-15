module Impasse
  class ExecutionHistory < ActiveRecord::Base
    unloadable
    set_table_name "impasse_execution_histories"
    self.include_root_in_json = false

    belongs_to :test_plan_case
    belongs_to :executor, :class_name => "User"
    acts_as_customizable
  end
end
