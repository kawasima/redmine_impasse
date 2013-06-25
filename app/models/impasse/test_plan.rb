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

    def self.get_statistics_for_plan(version, plan)
      total = count_by_sql ["SELECT count(status) FROM impasse_executions WHERE test_plan_case_id IN (SELECT id FROM impasse_test_plan_cases WHERE test_plan_id IN(SELECT id FROM impasse_test_plans WHERE name = '#{plan}' AND version_id = ((SELECT id FROM versions WHERE name = '#{version}'))))"]
      ok = count_by_sql ["SELECT count(status) FROM impasse_executions WHERE status = '1' AND test_plan_case_id IN (SELECT id FROM impasse_test_plan_cases WHERE test_plan_id IN(SELECT id FROM impasse_test_plans WHERE name = '#{plan}' AND version_id = ((SELECT id FROM versions WHERE name = '#{version}'))))"]
      nog = count_by_sql ["SELECT count(status) FROM impasse_executions WHERE status = '2' AND test_plan_case_id IN (SELECT id FROM impasse_test_plan_cases WHERE test_plan_id IN(SELECT id FROM impasse_test_plans WHERE name = '#{plan}' AND version_id = ((SELECT id FROM versions WHERE name = '#{version}'))))"]
      block = count_by_sql ["SELECT count(status) FROM impasse_executions WHERE status = '3' AND test_plan_case_id IN (SELECT id FROM impasse_test_plan_cases WHERE test_plan_id IN(SELECT id FROM impasse_test_plans WHERE name = '#{plan}' AND version_id = ((SELECT id FROM versions WHERE name = '#{version}'))))"]
      nok = nog+block
      undone = total-nok-ok
      [total,ok,nog,block,undone]
    end
    
    def self.get_statistics(version)
      total = count_by_sql ["SELECT count(status) FROM impasse_executions WHERE test_plan_case_id IN (SELECT id FROM impasse_test_plan_cases WHERE test_plan_id IN (SELECT id FROM impasse_test_plans WHERE version_id IN (SELECT id FROM versions WHERE name = '#{version}')))"]
      ok = count_by_sql ["SELECT count(status) FROM impasse_executions WHERE status = '1' AND test_plan_case_id IN (SELECT id FROM impasse_test_plan_cases WHERE test_plan_id IN (SELECT id FROM impasse_test_plans WHERE version_id IN (SELECT id FROM versions WHERE name = '#{version}')))"]
      nog = count_by_sql ["SELECT count(status) FROM impasse_executions WHERE status = '2' AND test_plan_case_id IN (SELECT id FROM impasse_test_plan_cases WHERE test_plan_id IN (SELECT id FROM impasse_test_plans WHERE version_id IN (SELECT id FROM versions WHERE name = '#{version}')))"]
      block = count_by_sql ["SELECT count(status) FROM impasse_executions WHERE status = '3' AND test_plan_case_id IN (SELECT id FROM impasse_test_plan_cases WHERE test_plan_id IN (SELECT id FROM impasse_test_plans WHERE version_id IN (SELECT id FROM versions WHERE name = '#{version}')))"]
      nok = nog+block
      undone = total-nok-ok
      [total,ok,nog,block,undone]
    end
    
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
    
    def self.find_test_cases(version_id)
      find_by_sql ["SELECT DISTINCT n.id AS id FROM impasse_test_plan_cases tpc	JOIN impasse_test_plans tp ON tp.id = tpc.test_plan_id JOIN impasse_test_cases tc ON tc.id = tpc.test_case_id JOIN impasse_nodes AS n ON n.id = tc.id WHERE tp.version_id = #{version_id} AND tc.active"]
    end
    
    def self.find_test_case_name(test_case_id)
      result = find_by_sql ["SELECT name FROM impasse_nodes WHERE id = #{test_case_id}"]
      result[0].name 
    end
    
    def self.find_version_name(version_id)
      result = find_by_sql ["SELECT name FROM versions WHERE id = #{version_id}"]
      result[0].name
    end
    
    def self.find_test_coverage(version_id, test_case_id)
      total = count_by_sql ["SELECT count(*) FROM impasse_executions e JOIN impasse_test_plan_cases tpc ON tpc.id = e.test_plan_case_id JOIN impasse_test_plans tp ON tp.id = tpc.test_plan_id JOIN impasse_test_cases tc ON tc.id = tpc.test_case_id WHERE tp.version_id = #{version_id} AND tc.id = #{test_case_id} AND tc.active"]
      ok = count_by_sql ["SELECT count(*) FROM impasse_executions e JOIN impasse_test_plan_cases tpc ON tpc.id = e.test_plan_case_id JOIN impasse_test_plans tp ON tp.id = tpc.test_plan_id JOIN impasse_test_cases tc ON tc.id = tpc.test_case_id WHERE tp.version_id = #{version_id} AND tc.id = #{test_case_id} AND e.status = '1' AND tc.active"]
      nog = count_by_sql ["SELECT count(*) FROM impasse_executions e JOIN impasse_test_plan_cases tpc ON tpc.id = e.test_plan_case_id JOIN impasse_test_plans tp ON tp.id = tpc.test_plan_id JOIN impasse_test_cases tc ON tc.id = tpc.test_case_id WHERE tp.version_id = #{version_id} AND tc.id = #{test_case_id} AND e.status = '2' AND tc.active"]
      block = count_by_sql ["SELECT count(*) FROM impasse_executions e JOIN impasse_test_plan_cases tpc ON tpc.id = e.test_plan_case_id JOIN impasse_test_plans tp ON tp.id = tpc.test_plan_id JOIN impasse_test_cases tc ON tc.id = tpc.test_case_id WHERE tp.version_id = #{version_id} AND tc.id = #{test_case_id} AND e.status = '3' AND tc.active"]
      nok = nog+block
      undone = total-nok-ok
      [total,ok,nog,block,undone]
    end
    
    def self.find_test_coverage_stats(version_id)
      total = count_by_sql ["SELECT count(*) FROM impasse_executions e JOIN impasse_test_plan_cases tpc ON tpc.id = e.test_plan_case_id JOIN impasse_test_plans tp ON tp.id = tpc.test_plan_id JOIN impasse_test_cases tc ON tc.id = tpc.test_case_id WHERE tp.version_id = #{version_id} AND tc.active"]
      ok = count_by_sql ["SELECT count(*) FROM impasse_executions e JOIN impasse_test_plan_cases tpc ON tpc.id = e.test_plan_case_id JOIN impasse_test_plans tp ON tp.id = tpc.test_plan_id JOIN impasse_test_cases tc ON tc.id = tpc.test_case_id WHERE tp.version_id = #{version_id} AND e.status = '1' AND tc.active"]
      nog = count_by_sql ["SELECT count(*) FROM impasse_executions e JOIN impasse_test_plan_cases tpc ON tpc.id = e.test_plan_case_id JOIN impasse_test_plans tp ON tp.id = tpc.test_plan_id JOIN impasse_test_cases tc ON tc.id = tpc.test_case_id WHERE tp.version_id = #{version_id} AND e.status = '2' AND tc.active"]
      block = count_by_sql ["SELECT count(*) FROM impasse_executions e JOIN impasse_test_plan_cases tpc ON tpc.id = e.test_plan_case_id JOIN impasse_test_plans tp ON tp.id = tpc.test_plan_id JOIN impasse_test_cases tc ON tc.id = tpc.test_case_id WHERE tp.version_id = #{version_id} AND e.status = '3' AND tc.active"]
      nok = nog+block
      undone = total-nok-ok
      [total,ok,nog,block,undone]
    end
    
    def self.find_testers(case_id)
      find_by_sql ["SELECT tp.id AS id, tp.name AS name, u.id AS u_id, u.firstname AS fname, u.lastname AS lname FROM users u JOIN impasse_executions e ON e.tester_id = u.id JOIN impasse_test_plan_cases tpc ON tpc.id = e.test_plan_case_id JOIN impasse_test_plans tp ON tp.id = tpc.test_plan_id JOIN impasse_test_cases tc ON tc.id = tpc.test_case_id JOIN impasse_nodes AS n ON n.id = tc.id WHERE tc.id = #{case_id} AND tc.active ORDER BY tp.name"]
    end
    
    def self.find_case_coverage(case_id, plan_id)
      total = count_by_sql ["SELECT count(e.status) FROM users u JOIN impasse_executions e ON e.tester_id = u.id JOIN impasse_test_plan_cases tpc ON tpc.id = e.test_plan_case_id JOIN impasse_test_plans tp ON tp.id = tpc.test_plan_id JOIN impasse_test_cases tc ON tc.id = tpc.test_case_id JOIN impasse_nodes AS n ON n.id = tc.id WHERE tc.id = #{case_id} AND tc.active AND tp.id = #{plan_id}"]
      ok = count_by_sql ["SELECT count(e.status) FROM users u JOIN impasse_executions e ON e.tester_id = u.id JOIN impasse_test_plan_cases tpc ON tpc.id = e.test_plan_case_id JOIN impasse_test_plans tp ON tp.id = tpc.test_plan_id JOIN impasse_test_cases tc ON tc.id = tpc.test_case_id JOIN impasse_nodes AS n ON n.id = tc.id WHERE tc.id = #{case_id} AND tc.active AND tp.id = #{plan_id} AND e.status = '1'"]
      nog = count_by_sql ["SELECT count(e.status) FROM users u JOIN impasse_executions e ON e.tester_id = u.id JOIN impasse_test_plan_cases tpc ON tpc.id = e.test_plan_case_id JOIN impasse_test_plans tp ON tp.id = tpc.test_plan_id JOIN impasse_test_cases tc ON tc.id = tpc.test_case_id JOIN impasse_nodes AS n ON n.id = tc.id WHERE tc.id = #{case_id} AND tc.active AND tp.id = #{plan_id} AND e.status = '2'"]
      block = count_by_sql ["SELECT count(e.status) FROM users u JOIN impasse_executions e ON e.tester_id = u.id JOIN impasse_test_plan_cases tpc ON tpc.id = e.test_plan_case_id JOIN impasse_test_plans tp ON tp.id = tpc.test_plan_id JOIN impasse_test_cases tc ON tc.id = tpc.test_case_id JOIN impasse_nodes AS n ON n.id = tc.id WHERE tc.id = #{case_id} AND tc.active AND tp.id = #{plan_id} AND e.status = '3'"]
      nok = nog+block
      undone = total-nok-ok
      [total,ok,nog,block,undone]
    end
  end
end
