class CreateNodes < ActiveRecord::Migration
  def self.up
    create_table :impasse_nodes do |t|
      t.column :name, :string
      t.references :node_type, :null => false
      t.references :parent, :class_name=>'Node'
      t.column :node_order, :integer
      t.column :path, :string, :null => false
    end
  end

  def self.down
    drop_table :impasse_nodes
  end
end
