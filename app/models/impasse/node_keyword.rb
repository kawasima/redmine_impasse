module Impasse
  class NodeKeyword < ActiveRecord::Base
    unloadable
    self.table_name = "impasse_node_keywords"
    self.include_root_in_json = false

    attr_accessible :keyword, :project_id, :keyword_id, :node_id

    belongs_to :node
    belongs_to :keyword
  end
end
