class CreateImpasseSettings < ActiveRecord::Migration
  def self.up
    create_table :impasse_settings do |t|
      t.references :project, :null => false
      t.column :bug_tracker_id, :integer
    end
    add_index :impasse_settings, :project_id, :name => 'IDX_IMPASSE_SETTINGS_01'
  end

  def self.down
    drop_table :impasse_settings
  end
end
