module Impasse
  class NodeKeyword < ActiveRecord::Base
    unloadable
    set_table_name "impasse_node_keywords"

    belongs_to :node
    belongs_to :keyword
  end
end
