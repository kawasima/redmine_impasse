class CreateExecutions < ActiveRecord::Migration
  def self.up
    create_table :impasse_executions do |t|
      t.column :test_plan_case_id, :integer, :null=>false
      t.column :tester_id, :integer
      t.column :build_id, :integer
      t.column :expected_date, :date
      t.column :status, :string, :length => 1, :default=>'0'
      t.column :execution_ts, :datetime
      t.column :notes, :text
    end

    add_index :impasse_executions, :test_plan_case_id, :name => 'IDX_IMPASSE_EXECUTIONS_01'
    add_index :impasse_executions, :tester_id, :name => 'IDX_IMPASSE_EXECUTIONS_02'
    add_index :impasse_executions, :execution_ts, :name => 'IDX_IMPASSE_EXECUTIONS_03'
  end

  def self.down
    drop_table :impasse_executions
  end
end
