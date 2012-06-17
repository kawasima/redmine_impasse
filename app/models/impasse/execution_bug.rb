module Impasse
  class ExecutionBug < ActiveRecord::Base
    unloadable
    set_table_name "impasse_execution_bugs"
    self.include_root_in_json = false

    belongs_to :issue, :foreign_key => :bug_id
    belongs_to :execution
  end
end
