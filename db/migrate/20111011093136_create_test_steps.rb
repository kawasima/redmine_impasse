class CreateTestSteps < ActiveRecord::Migration
  def self.up
    create_table :impasse_test_steps do |t|
      t.references :test_case, :null => false
      t.column :step_number, :integer
      t.column :actions, :text
      t.column :expected_results, :text
    end

    add_index :impasse_test_steps, :test_case_id, :name => 'IDX_IMPASSE_TEST_STEPS_01'
  end

  def self.down
    drop_table :impasse_test_steps
  end
end
