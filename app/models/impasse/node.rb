module Impasse
  class Node < ActiveRecord::Base
    unloadable
    set_table_name "impasse_nodes"

    belongs_to :parent, :class_name=>'Node', :foreign_key=> :parent_id
    has_many   :children, :class_name=> 'Node', :foreign_key=> :parent_id

    def is_test_case?
      self.node_type_id == 3
    end

    def is_test_suite?
      self.node_type_id == 2
    end

    def self.find_children(node_id, test_plan_id=nil)
      sql = <<-'END_OF_SQL'
      SELECT distinct parent.*
        FROM impasse_nodes AS parent
      LEFT JOIN impasse_nodes AS child
        ON INSTR(child.path, parent.path) > 0
      LEFT JOIN impasse_test_cases AS tc
        ON child.id = tc.id
      <% if conditions.include? :test_plan_id %>
      LEFT JOIN impasse_test_plan_cases AS tpts
        ON tc.id=tpts.test_case_id
      <% end %>
      WHERE 1=1
      <% if conditions.include? :test_plan_id %>
      AND tpts.test_plan_id=:test_plan_id
      <% end %>
      <% if conditions.include? :path %>
        AND parent.path LIKE :path
      <% end %>
      ORDER BY LENGTH(parent.path) - LENGTH(REPLACE(parent.path,'.','')), node_order
      END_OF_SQL

      conditions = {}
    
      unless test_plan_id.nil?
        conditions[:test_plan_id] = test_plan_id
      end

      unless node_id.to_i == -1
        node = find(node_id)
        conditions[:path] = "#{node.path}_%"
      end
    
      find_by_sql([ERB.new(sql).result(binding), conditions])
    end

    def all_decendant_cases
      sql = <<-'END_OF_SQL'
      SELECT distinct parent.*
        FROM impasse_nodes AS parent
      LEFT JOIN impasse_nodes AS child
        ON INSTR(child.path, parent.path) > 0
      LEFT JOIN impasse_test_cases AS tc
        ON child.id = tc.id
      WHERE parent.path LIKE :path
        AND parent.node_type_id=3
      END_OF_SQL
      conditions = {:path => "#{self.path}%"}
      Node.find_by_sql([ERB.new(sql).result(binding), conditions])
    end

    def save!
      if new_record?
        # dummy path
        write_attribute(:path, ".")
        super
      end

      recalculate_path
      super
    end

    def save
      if new_record?
        # dummy path
        write_attribute(:path, ".")
        return false unless super
      end

      recalculate_path
      super
    end

    def update_siblings_order!(old_node)
      sql = if old_node.parent_id == self.parent_id
              if self.node_order < old_node.node_order
                <<-END_OF_SQL
UPDATE impasse_nodes
SET node_order = node_order + 1
WHERE parent_id = #{self.parent_id}
  AND node_order >= #{self.node_order} 
  AND node_order < #{old_node.node_order}
  AND id != #{self.id}
                END_OF_SQL
              else
                <<-END_OF_SQL
UPDATE impasse_nodes
SET node_order = node_order - 1
WHERE parent_id = #{self.parent_id}
  AND node_order > #{old_node.node_order} 
  AND node_order <= #{self.node_order}
  AND id != #{self.id}
                END_OF_SQL
              end
            else
              <<-END_OF_SQL
UPDATE impasse_nodes
SET node_order = node_order + 1
WHERE parent_id = #{self.parent_id}
  AND node_order >= #{self.node_order} 
  AND id != #{self.id}
                END_OF_SQL
            end
      connection.update(sql)
    end
 
    def update_child_nodes_path(old_path)
      sql = <<-END_OF_SQL
      UPDATE impasse_nodes
      SET path = replace(path, '#{old_path}', '#{self.path}')
      WHERE path like '#{old_path}_%'
      END_OF_SQL
      
      connection.update(sql)
    end

    private
    def recalculate_path
      if parent.nil?
        write_attribute(:path, ".#{read_attribute(:id)}.")
      else
        write_attribute(:path, "#{parent.path}#{read_attribute(:id)}.")
      end
    end
  end
end
