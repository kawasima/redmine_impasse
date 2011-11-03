class CreateTestCases < ActiveRecord::Migration
  def self.up
    create_table :impasse_test_cases do |t|
      t.column :layout, :integer
      t.column :status, :integer
      t.column :summary, :text
      t.column :preconditions, :text
      t.column :importance, :integer
      t.column :author_id, :integer
      t.column :creation_ts, :timestamp
      t.column :update_id, :integer
      t.column :modification_ts, :timestamp
      t.column :active, :boolean
      t.column :execution_type, :integer
    end

    add_index :impasse_test_cases, :author_id, :name => 'IDX_IMPASSE_TEST_CASES_01'
    add_index :impasse_test_cases, :update_id, :name => 'IDX_IMPASSE_TEST_CASES_02'
  end

  def self.down
    drop_table :impasse_test_cases
  end
end
