module Impasse
  class NodeKeyword < ActiveRecord::Base
    unloadable
    set_table_name "impasse_node_keywords"
    self.include_root_in_json = false

    belongs_to :node
    belongs_to :keyword
  end
end
