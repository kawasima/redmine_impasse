class CreateTestPlanCases < ActiveRecord::Migration
  def self.up
    create_table :impasse_test_plan_cases do |t|
      t.column :test_plan_id, :integer
      t.column :test_case_id, :integer
      t.column :node_order, :integer
      t.column :urgency, :integer
    end
  end

  def self.down
    drop_table :impasse_test_plan_cases
  end
end
