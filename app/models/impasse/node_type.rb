module Impasse
  class NodeType < ActiveRecord::Base
    unloadable
    set_table_name "impasse_node_types"
    self.include_root_in_json = false
  end
end
