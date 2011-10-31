module Impasse
  class ExecutionBug < ActiveRecord::Base
    unloadable
    set_table_name "impasse_execution_bugs"

    belongs_to :issue, :foreign_key => :bug_id
    belongs_to :execution
  end
end
