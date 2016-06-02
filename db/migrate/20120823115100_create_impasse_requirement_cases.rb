class CreateImpasseRequirementCases < ActiveRecord::Migration
  def self.up
    create_table :impasse_requirement_cases do |t|
      t.column :requirement_id, :integer, :null => false
      t.column :test_case_id, :integer, :null => false
    end
  end

  def self.down
    drop_table :impasse_requirement_cases
  end
end
