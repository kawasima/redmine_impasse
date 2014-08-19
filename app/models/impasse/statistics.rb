module Impasse
  class Statistics < ActiveRecord::Base
    unloadable
    set_table_name 'impasse_test_plans'
    self.include_root_in_json = false

    def self.summary_default(test_plan_id, test_suite_id=nil)
      conditions = { :test_plan_id => test_plan_id }
      concatinated_path = case configurations[Rails.env]['adapter']
                          when /mysql/
                            "CONCAT(:path, head.id, '.')"
                          when /sqlserver/
                            ":path + head.id + '.'" # Not tested
                          else
                            ":path || head.id || '.'"
                          end
                            
      if test_suite_id
        suite = Node.find(test_suite_id)
        conditions[:path] = suite.path
        conditions[:path_starts_with] = "#{suite.path}_%"
        conditions[:level] = suite.path.count('.') + 1
      end
      sql = <<-END_OF_SQL
      SELECT 
      <%- if conditions[:path] -%>
        head.id AS id, head.name AS name, head.node_type_id AS node_type_id,
      <%- else -%>
        tp.id AS id, tp.name AS name, 1 AS node_type_id,
      <%- end -%>
        count(*) AS total_cases,
        SUM(CASE WHEN exe.status IS NULL OR exe.status='0' THEN 1 ELSE 0 END) AS unexec,
        SUM(CASE WHEN exe.status='1' THEN 1 ELSE 0 END) AS ok,
        SUM(CASE WHEN exe.status='2' THEN 1 ELSE 0 END) AS ng,
        SUM(CASE WHEN exe.status='3' THEN 1 ELSE 0 END) AS block,
        SUM(CASE WHEN eb.bugs IS NULL THEN 0 ELSE eb.bugs END) AS bugs,
        SUM(CASE WHEN eb.closed_bugs IS NULL THEN 0 ELSE eb.closed_bugs END) AS closed_bugs
      FROM impasse_test_cases AS tc
      INNER JOIN impasse_test_plan_cases AS tpc
        ON tc.id = tpc.test_case_id
      INNER JOIN impasse_test_plans AS tp
        ON tp.id = tpc.test_plan_id
      INNER JOIN impasse_nodes AS n
        ON tc.id = n.id
      <%- if conditions[:path] -%>
      INNER JOIN impasse_nodes AS head
        ON head.path = SUBSTR(n.path, 1, LENGTH(<%=concatinated_path%>))
      <%- end -%>
      LEFT OUTER JOIN impasse_executions AS exe
        ON exe.test_plan_case_id = tpc.id
      LEFT OUTER JOIN (
        SELECT bug.execution_id, count(*) AS bugs, SUM(CASE WHEN st.is_closed = '1' THEN 1 ELSE 0 END) AS closed_bugs
        FROM impasse_execution_bugs AS bug
        INNER JOIN issues
          ON bug.bug_id = issues.id
        INNER JOIN issue_statuses AS st
          ON issues.status_id = st.id
        GROUP BY bug.execution_id
      ) AS eb
        ON eb.execution_id = exe.id
      WHERE tp.id = :test_plan_id
      <%- if conditions[:path] -%>
        AND n.path LIKE :path_starts_with
        AND LENGTH(head.path) - LENGTH(REPLACE(head.path, '.', '')) = :level
      GROUP BY head.id, head.name, head.node_type_id, SUBSTR(n.path, 1, LENGTH(<%=concatinated_path%>))
      <%- else -%>
      GROUP BY tp.id, tp.name, node_type_id
      <%- end -%>
      END_OF_SQL

      results = find_by_sql([ERB.new(sql, nil, '-').result(binding), conditions])
      tc_summary = nil

      results.delete_if{|r|
        if r.node_type_id.to_i == 3
          if tc_summary
            [:total_cases, :unexec, :ok, :ng, :block, :bugs, :closed_bugs].each{|name|
              tc_summary[name] = tc_summary[name].to_i + r[name].to_i
            }
          else
            tc_summary = r.clone
            tc_summary.id = nil
            tc_summary.name = "(#{l(:field_test_case)})"
          end
        end
        r.node_type_id.to_i == 3
      }
      results << tc_summary if tc_summary
      results
    end

    def self.summary_members(test_plan_id, test_suite_id=nil)
      sql = <<-END_OF_SQL
SELECT users.id, users.login, users.mail, users.firstname, users.lastname, stat.*
FROM (
SELECT
  exe.tester_id,
  SUM(1) AS assigned,
  SUM(CASE exe.status WHEN '1' THEN 1 ELSE 0 END) AS ok,
  SUM(CASE exe.status WHEN '2' THEN 1 ELSE 0 END) AS ng,
  SUM(CASE exe.status WHEN '3' THEN 1 ELSE 0 END) AS block
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
SELECT CASE WHEN execution_ts IS NULL OR exe.status='0' THEN NULL ELSE cast(execution_ts as date) END AS execution_date,
  SUM(CASE exe.status WHEN '1' THEN 1 ELSE 0 END) AS ok,
  SUM(CASE exe.status WHEN '2' THEN 1 ELSE 0 END) AS ng,
  SUM(CASE exe.status WHEN '3' THEN 1 ELSE 0 END) AS block,
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

      expected_sql = <<-END_OF_SQL
      SELECT  expected_date, count(*) AS total
      FROM impasse_test_cases AS tc
      INNER JOIN impasse_test_plan_cases AS tpc
        ON tpc.test_case_id = tc.id
      LEFT OUTER JOIN impasse_executions AS exe
        ON exe.test_plan_case_id = tpc.id
      WHERE tpc.test_plan_id = :test_plan_id
      GROUP BY expected_date
      END_OF_SQL
      expected_statistics = find_by_sql([expected_sql, {:test_plan_id => test_plan_id}])

      res = [[], [], []]
      sum = { :remain => 0, :expected => 0, :bug => 0}

      start_date = end_date = nil

      statistics.each{|st|
        if st.execution_date
          start_date = st.execution_date.to_date if start_date.nil? or st.execution_date.to_date < start_date
          end_date   = st.execution_date.to_date if end_date.nil? or st.execution_date.to_date > end_date
        end
        sum[:remain] += st.total.to_i
      }
      expected_statistics.each{|st|
        if st.expected_date
          start_date = st.expected_date.to_date if start_date.nil? or st.expected_date.to_date < start_date
          end_date   = st.expected_date.to_date if end_date.nil? or st.expected_date.to_date > end_date
        end
        sum[:expected] += st.total.to_i
      }
      start_date = Date.today if start_date.nil?
      end_date   = Date.today if end_date.nil?
      (start_date-1..end_date).each{|d|
        st = statistics.detect{|st| st.execution_date and st.execution_date.to_date == d}
        if st
          sum[:bug] += st.ng.to_i
          sum[:remain] -= st.total.to_i
        end
        exp_st = expected_statistics.detect{|st| st.expected_date and st.expected_date.to_date == d}
        if exp_st
          sum[:expected] -= exp_st.total.to_i
        end

        res[0] << [ d.to_date, sum[:expected] ]
        res[1] << [ d.to_date, sum[:remain]]
        res[2] << [ d.to_date, sum[:bug] ]
      }
      res
    end
  end
end
