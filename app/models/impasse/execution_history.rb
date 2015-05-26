module Impasse
  class ExecutionHistory < ActiveRecord::Base
    unloadable
    self.table_name = "impasse_execution_histories"
    self.include_root_in_json = false

    attr_accessible :id, :test_plan_case_id, :tester_id, :build_id, :expected_date, :status, :execution_ts, :notes, :executor_id

    belongs_to :test_plan_case
    belongs_to :executor, :class_name => "User"
    acts_as_customizable
  end
end
