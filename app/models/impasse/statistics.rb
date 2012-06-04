module Impasse
  class Statistics < ActiveRecord::Base
    unloadable
    set_table_name 'impasse_test_plans'

    def self.summary_default(test_plan_id, test_suite_id=nil)
      conditions = { :test_plan_id => test_plan_id }
      if test_suite_id
        suite = Node.find(test_suite_id)
        conditions[:path] = "#{suite.path}_%"
      end
      sql = <<-END_OF_SQL
      SELECT 
      <% if conditions[:path] %>
        head.id AS id, head.name AS name,
      <% else %>
        tp.id AS id, tp.name AS name,
      <% end %>
        count(*) AS total_cases,
        SUM(CASE WHEN exe.status IS NULL OR exe.status=0 THEN 0 ELSE 1 END) AS total_executions,
        SUM(CASE WHEN bug.bug_id  IS NULL THEN 0 ELSE 1 END) AS total_bugs
      FROM impasse_test_cases AS tc
      INNER JOIN impasse_test_plan_cases AS tpc
        ON tc.id = tpc.test_case_id
      INNER JOIN impasse_test_plans AS tp
        ON tp.id = tpc.test_plan_id
      INNER JOIN impasse_nodes AS n
        ON tc.id = n.id
      <% if conditions[:path] %>
      INNER JOIN impasse_nodes AS head
        ON head.path = concat(substring_index(n.path, '.', length(:path) - length(replace(:path, '.', '')) + 1), '.')
      <% end %>
      LEFT OUTER JOIN impasse_executions AS exe
        ON exe.test_plan_case_id = tpc.id
      LEFT OUTER JOIN impasse_execution_bugs AS bug
        ON exe.id = bug.execution_id
      WHERE tp.id = :test_plan_id
      <% if conditions[:path] %>
        AND n.path LIKE :path
      GROUP BY substring_index(n.path, '.', length(:path) - length(replace(:path, '.', '')) + 1)
      <% end %>
      END_OF_SQL
      find_by_sql([ERB.new(sql).result(binding), conditions])
    end

    def self.summary_members(test_plan_id, test_suite_id=nil)
      sql = <<-END_OF_SQL
SELECT users.id, users.login, users.mail, users.firstname, users.lastname, stat.*
FROM (
SELECT
  exe.tester_id,
  SUM(1) AS assigned,
  SUM(CASE exe.status WHEN 1 THEN 1 ELSE 0 END) AS ok,
  SUM(CASE exe.status WHEN 2 THEN 1 ELSE 0 END) AS ng,
  SUM(CASE exe.status WHEN 3 THEN 1 ELSE 0 END) AS block
FROM impasse_test_cases AS tc
INNER JOIN impasse_test_plan_cases AS tpc
  ON tpc.test_case_id = tc.id
LEFT OUTER JOIN impasse_executions AS exe
  ON exe.test_plan_case_id = tpc.id
WHERE tpc.test_plan_id=?
GROUP BY tester_id
) AS stat
LEFT OUTER JOIN users
  ON users.id = stat.tester_id
      END_OF_SQL
      find_by_sql([sql, test_plan_id])
    end

    def self.summary_daily(test_plan_id, test_suite_id=nil)
      sql = <<-END_OF_SQL
SELECT CASE WHEN execution_ts IS NULL OR exe.status=0 THEN NULL ELSE date_format(execution_ts, '%Y%m%d') END AS execution_date,
  SUM(CASE exe.status WHEN 1 THEN 1 ELSE 0 END) AS ok,
  SUM(CASE exe.status WHEN 2 THEN 1 ELSE 0 END) AS ng,
  SUM(CASE exe.status WHEN 3 THEN 1 ELSE 0 END) AS block,
  SUM(1) AS total
FROM impasse_test_cases AS tc
INNER JOIN impasse_test_plan_cases AS tpc
  ON tpc.test_case_id = tc.id
LEFT OUTER JOIN impasse_executions AS exe
  ON exe.test_plan_case_id = tpc.id
WHERE tpc.test_plan_id=?
GROUP BY execution_date
      END_OF_SQL
      statistics = find_by_sql([sql, test_plan_id])

      res = [[], []]
      remain = 0
      bug = 0
      start_date = Date.today
      statistics.each{|st|
        start_date = st.execution_date.to_date if !st.execution_date.nil? and st.execution_date.to_date < start_date
        remain += st.total.to_i
      }
      test_plan = TestPlan.find(test_plan_id) 
      end_date = test_plan.version.effective_date
      (start_date-1..end_date).each{|d|
        st = statistics.find{|st| !st.execution_date.nil? and st.execution_date.to_date == d}
        unless st.nil?
          bug += st.ng.to_i
          remain -= st.total.to_i
        end
        res[0] << [ d.to_date, remain ]
        res[1] << [ d.to_date, bug]
      }
      res
    end
  end
end
