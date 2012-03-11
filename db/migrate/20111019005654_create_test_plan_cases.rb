class CreateTestPlanCases < ActiveRecord::Migration
  def self.up
    create_table :impasse_test_plan_cases do |t|
      t.column :test_plan_id, :integer, :nullable => false
      t.column :test_case_id, :integer, :nullable => false
      t.column :node_order, :integer
    end

    add_index :impasse_test_plan_cases, [:test_plan_id,:test_case_id], :name => 'IDX_IMPASSE_TEST_PLAN_CASES_01'
  end

  def self.down
    drop_table :impasse_test_plan_cases
  end
end
