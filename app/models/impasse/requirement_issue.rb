module Impasse
  class RequirementIssue < ActiveRecord::Base
    unloadable
    self.table_name = "impasse_requirement_issues"

    attr_accessible :issue_id

    belongs_to :issue
    has_many :requirement_cases, :foreign_key => "requirement_id"
    has_many :test_cases, :through => :requirement_cases
  end
end
