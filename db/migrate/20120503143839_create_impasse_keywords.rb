class CreateImpasseKeywords < ActiveRecord::Migration
  def self.up
    create_table :impasse_keywords do |t|
      t.column :keyword, :string, :null => false
      t.references :project, :null => false
    end
    add_index :impasse_keywords, :project_id, :name => 'IDX_IMPASSE_KEYWORDS_01'
  end

  def self.down
    drop_table :impasse_keywords
  end
end
