module Impasse
  class Execution < ActiveRecord::Base
    unloadable
    set_table_name "impasse_executions"

    belongs_to :test_plan_case
    has_many :issues, :through => :execution_bugs
    has_many :execution_bugs
  end
end
