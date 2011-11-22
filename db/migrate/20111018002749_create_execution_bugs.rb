class CreateExecutionBugs < ActiveRecord::Migration
  def self.up
    create_table :impasse_execution_bugs do |t|
      t.column :execution_id, :integer
      t.column :bug_id, :integer
    end

    add_index :impasse_execution_bugs, :execution_id, :name => 'IDX_IMPASSE_EXECUTION_BUGS_01'
    add_index :impasse_execution_bugs, :bug_id, :name => 'IDX_IMPASSE_EXECUTION_BUGS_02'
  end

  def self.down
    drop_table :impasse_execution_bugs
  end
end
