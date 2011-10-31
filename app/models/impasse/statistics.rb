module Impasse
  class Statistics < ActiveRecord::Base
    unloadable
    set_table_name 'impasse_test_plans'

    def self.summary_default(test_plan_id)
      sql = <<-END_OF_SQL
      SELECT tp.id, tp.name, count(*) AS total_cases,
        SUM(CASE WHEN exe.status IS NULL OR exe.status=0 THEN 0 ELSE 1 END) AS total_executions,
        SUM(CASE WHEN bug.bug_id  IS NULL THEN 0 ELSE 1 END) AS total_bugs
      FROM impasse_test_cases AS tc
      INNER JOIN impasse_test_plan_cases AS tpc
        ON tc.id = tpc.test_case_id
      INNER JOIN impasse_test_plans AS tp
        ON tp.id = tpc.test_plan_id
      LEFT OUTER JOIN impasse_executions AS exe
        ON exe.test_plan_case_id = tpc.id
      LEFT OUTER JOIN impasse_execution_bugs AS bug
        ON exe.id = bug.execution_id
      WHERE tp.id=?
      END_OF_SQL
      find_by_sql([sql, test_plan_id]).first
    end
    def self.summary_members(test_plan_id)
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

    def self.summary_daily(test_plan_id)
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
      find_by_sql([sql, test_plan_id])
    end
  end
end
