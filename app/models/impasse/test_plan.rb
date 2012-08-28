module Impasse
  class TestPlan < ActiveRecord::Base
    unloadable
    set_table_name "impasse_test_plans"
    self.include_root_in_json = false

    has_many :test_plan_cases
    has_many :test_cases, :through => :test_plan_cases
    belongs_to :version

    RELATED_REQUIREMENTS_BASE_SQL = <<-'END_OF_SQL'
FROM issues
LEFT OUTER JOIN (
  SELECT ri.issue_id, ri.num_of_cases AS needed, count(*) AS actual, count(tpc.id) AS planned
    FROM impasse_requirement_issues AS ri
    JOIN impasse_requirement_cases AS rc ON rc.requirement_id = ri.id
    JOIN impasse_test_cases AS tc ON tc.id = rc.test_case_id
    JOIN impasse_nodes AS n ON n.id = tc.id
    LEFT OUTER JOIN impasse_test_plan_cases AS tpc
      ON tpc.test_case_id = tc.id                                                                              AND tpc.test_plan_id = <%= id %>
   GROUP BY ri.issue_id, ri.num_of_cases
) AS r
  ON r.issue_id = issues.id
WHERE issues.fixed_version_id = <%= version.id %>
END_OF_SQL
    RELATED_REQUIREMENTS_FINDER_SQL  = ERB.new("SELECT issues.id AS issue_id, issues.subject, r.needed, r.actual, r.planned " + RELATED_REQUIREMENTS_BASE_SQL)
    RELATED_REQUIREMENTS_COUNTER_SQL = ERB.new("SELECT count(*) " + RELATED_REQUIREMENTS_BASE_SQL)

    has_many :related_requirements, {
      :class_name => Impasse::RequirementStats,
      :readonly => true,
      :finder_sql => Proc.new { RELATED_REQUIREMENTS_FINDER_SQL.result(binding) },
      :counter_sql => Proc.new { RELATED_REQUIREMENTS_COUNTER_SQL.result(binding) }
    }

    validates_presence_of :name
    validates_length_of :name, :maximum => 100

    acts_as_customizable

    def self.find_all_by_version(project, show_closed = false)
      versions = project.shared_versions || []
      versions = versions.uniq.sort
      unless show_closed
        versions.reject! {|version| version.closed? || version.completed? }
      end

      test_plans_by_version = {}
      versions.each do |version|
        test_plans = TestPlan.find(:all, :conditions => ["version_id=?", version.id])
        test_plans_by_version[version] = test_plans
      end
      [test_plans_by_version, versions]
    end
  end
end
