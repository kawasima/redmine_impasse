module Impasse
  class NodeType < ActiveRecord::Base
    unloadable
    set_table_name "impasse_node_types"
  end
end
