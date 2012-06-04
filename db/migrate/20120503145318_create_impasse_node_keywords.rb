class CreateImpasseNodeKeywords < ActiveRecord::Migration
  def self.up
    create_table :impasse_node_keywords do |t|
      t.column :node_id, :integer, :null => false
      t.column :keyword_id, :integer, :null => false
    end

    add_index :impasse_node_keywords, [:node_id,:keyword_id], :name => 'IDX_IMPASSE_NODE_KEYWORDS_01'
  end

  def self.down
    drop_table :impasse_node_keywords
  end
end
