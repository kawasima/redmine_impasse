module Impasse
  class TestPlan < ActiveRecord::Base
    unloadable
    set_table_name "impasse_test_plans"
    self.include_root_in_json = false

    has_many :test_plan_cases
    has_many :test_cases, :through => :test_plan_cases
    belongs_to :version

    validates_presence_of :name
    validates_length_of :name, :maximum => 100
    validates_presence_of :version

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

    def setting
      @setting = Impasse::Setting.find_by_project_id(version.project.id)
    end

    def related_requirements
      Impasse::RequirementStats.find_by_sql([<<-END_OF_SQL, id, version.id, setting.requirement_tracker.map{|t| t.to_i}])
SELECT issues.id AS issue_id, issues.subject, r.needed, r.actual, r.planned
FROM issues
LEFT OUTER JOIN (
  SELECT ri.issue_id, ri.num_of_cases AS needed, count(*) AS actual, count(tpc.id) AS planned
    FROM impasse_requirement_issues AS ri
    JOIN impasse_requirement_cases AS rc ON rc.requirement_id = ri.id
    JOIN impasse_test_cases AS tc ON tc.id = rc.test_case_id
    JOIN impasse_nodes AS n ON n.id = tc.id
    LEFT OUTER JOIN impasse_test_plan_cases AS tpc
      ON tpc.test_case_id = tc.id AND tpc.test_plan_id = ?
   GROUP BY ri.issue_id, ri.num_of_cases
) AS r
  ON r.issue_id = issues.id
WHERE issues.fixed_version_id = ?
  AND issues.tracker_id in (?)
END_OF_SQL
    end

    if Rails::VERSION::MAJOR < 3 or (Rails::VERSION::MAJOR == 3 and Rails::VERSION::MINOR < 1)
      def dup
        clone
      end
    end
  end
end
