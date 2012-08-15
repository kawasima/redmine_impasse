class CreateImpasseExecutionHistories < ActiveRecord::Migration
  def self.up
    create_table :impasse_execution_histories do |t|
      t.column :test_plan_case_id, :integer, :null => false
      t.column :tester_id, :integer
      t.column :build_id, :integer
      t.column :expected_date, :date
      t.column :status, :string, :length => 1, :null => false
      t.column :execution_ts, :datetime, :null => false
      t.column :executor_id, :integer, :null => false
      t.column :notes, :text
    end

    add_index :impasse_execution_histories, :test_plan_case_id, :name => 'IDX_IMPASSE_EXEC_HIST_01'
  end

  def self.down
    drop_table :impasse_execution_histories
  end
end
