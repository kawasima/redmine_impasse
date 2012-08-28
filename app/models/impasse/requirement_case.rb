module Impasse
  class RequirementCase < ActiveRecord::Base
    unloadable
    set_table_name "impasse_requirement_cases"

    belongs_to :test_case
    belongs_to :requirement_issue, :foreign_key => "requirement_id"
  end
end
