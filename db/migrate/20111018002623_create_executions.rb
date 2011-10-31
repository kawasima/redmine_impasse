class CreateExecutions < ActiveRecord::Migration
  def self.up
    create_table :impasse_executions do |t|
      t.column :test_plan_case_id, :integer, :null=>false
      t.column :tester_id, :integer
      t.column :build_id, :integer
      t.column :expected_date, :date
      t.column :status, :string, :length => 1, :default=>'0'
      t.column :execution_ts, :datetime
      t.column :execution_type, :string, :length => 1
      t.column :notes, :text
    end
  end

  def self.down
    drop_table :impasse_executions
  end
end
