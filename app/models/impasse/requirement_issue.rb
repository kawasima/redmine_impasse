module Impasse
  class RequirementIssue < ActiveRecord::Base
    unloadable
    set_table_name "impasse_requirement_issues"

    belongs_to :issue
    has_many :requirement_cases, :foreign_key => "requirement_id"
    has_many :test_cases, :through => :requirement_cases
  end
end
