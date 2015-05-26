module Impasse
  class NodeType < ActiveRecord::Base
    unloadable
    self.table_name = "impasse_node_types"
    self.include_root_in_json = false
  end
end
