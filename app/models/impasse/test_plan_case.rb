module Impasse
  class TestPlanCase < ActiveRecord::Base
    unloadable
    set_table_name "impasse_test_plan_cases"
    self.include_root_in_json = false

    belongs_to :test_plan
    belongs_to :test_case
    has_many   :executions

    def self.delete_cascade!(test_plan_id, test_case_id)
      node = Node.find(test_case_id)

      sql = <<-END_OF_SQL
DELETE FROM impasse_test_plan_cases
WHERE test_plan_id=#{test_plan_id}
  AND test_case_id in (
    SELECT id
    FROM impasse_nodes
    WHERE path LIKE '#{node.path}%'
      AND node_type_id=3
  )
      END_OF_SQL
      
      connection.update(sql)
    end

    if Rails::VERSION::MAJOR < 3 or (Rails::VERSION::MAJOR == 3 and Rails::VERSION::MINOR < 1)
      def dup
        clone
      end
    end
  end
end
