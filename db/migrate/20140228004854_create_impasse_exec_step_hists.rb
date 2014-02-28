class CreateImpasseExecStepHists < ActiveRecord::Migration
  def change
    create_table :impasse_exec_step_hists do |t|
      t.belongs_to :test_steps
      t.belongs_to :test_plan_case
      t.belongs_to :issue
      t.integer :author_id, default: 0, null: false
      t.integer :project_id, default: 0, null: false
      t.column :test_plan_case_id, :integer, :null => false
      t.column :tester_id, :integer
      t.column :build_id, :integer
      t.column :expected_date, :date
      t.column :status, :string, :length => 1, :null => false
      t.column :execution_ts, :datetime, :null => false
      t.column :executor_id, :integer, :null => false
      t.timestamps :execution_ts
    end
    add_index :impasse_exec_step_hists, :test_steps_id
    add_index :impasse_exec_step_hists, :test_plan_case_id
    add_index :impasse_exec_step_hists, :issue_id
    add_index :impasse_exec_step_hists, :author_id
    add_index :impasse_exec_step_hists, :project_id
  end
  
   def self.down
    drop_table :impasse_exec_step_hists
  end
end
