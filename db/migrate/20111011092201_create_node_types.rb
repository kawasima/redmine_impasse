class CreateNodeTypes < ActiveRecord::Migration
  def self.up
    create_table :impasse_node_types do |t|
      t.column :description, :string
    end
    Impasse::NodeType.create(:id=>1, :description=>'testproject')
    Impasse::NodeType.create(:id=>2, :description=>'testsuite')
    Impasse::NodeType.create(:id=>3, :description=>'testcase')
  end 
  def self.down
    drop_table :impasse_node_types
  end
end
