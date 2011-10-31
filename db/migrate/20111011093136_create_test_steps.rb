class CreateTestSteps < ActiveRecord::Migration
  def self.up
    create_table :impasse_test_steps do |t|
      t.references :test_case, :null => false
      t.column :step_number, :integer
      t.column :actions, :text
      t.column :expected_results, :text
      t.column :active, :boolean
      t.column :execution_type, :integer
    end
  end

  def self.down
    drop_table :impasse_test_steps
  end
end
