require 'optparse'


namespace :redmine do
  namespace :impasse do
    desc "Export Redmine Impasse test cases."
    task :export => :environment do |t|
      if defined? JRUBY_VERSION
        require 'java'
        
        gem "activerecord-jdbc-adapter"
        require 'axebomber'

        java_import "net.unit8.axebomber.manager.impl.FileSystemBookManager"
        include Axebomber
      end

      raise "You must set RAILS_ENV" unless ENV["RAILS_ENV"]
      raise "You must run in jruby" unless defined? JRUBY_VERSION
      
      project = ENV['project'].to_s.strip
      project = nil if project == '' || project == '*'

      output_file = ENV['output'].to_s.strip || "export.xls"

      root = Impasse::Node.find_by_name_and_node_type_id(project, 1)
      nodes = Impasse::Node.find_children(root.id)
      nodes.unshift(root)

      tree, depth = convert(nodes)
      manager = FileSystemBookManager.new
      book = manager.create(output_file)
      sheet = book.getSheet("testcases");

      row = sheet.getRow(0)
      row.cell(0).value = "Id"
      row.cell(1).value = "Node type id"
      row.cell(depth + 1).value = "Details"
      row.cell(depth + 2).value = "Summary"
      row.cell(depth + 3).value = "Preconditions"
      row.cell(depth + 4).value = "Keywords"
      row.cell(depth + 5).value = "Actions"
      row.cell(depth + 6).value = "Expected results"
      sheet.titleRowIndex = 0
      traverse(tree[0], 0, sheet)
      
      manager.save(book)
    end

    def write_node(node, sheet)
      if node[:node_type_id] == 2
        test_suite = Impasse::TestSuite.find(node[:id])
        sheet.cell("Details").value = test_suite.details
      elsif node[:node_type_id] == 3
        test_case = Impasse::TestCase.find(:first, :conditions => ["id=?", node[:id]], :include => :test_steps)
        sheet.cell("Summary").value       = test_case.summary
        sheet.cell("Preconditions").value = test_case.preconditions
        test_case.test_steps.each_with_index do |step, i|
          sheet.nextRow unless i == 0
          sheet.cell("Actions").value          = step.actions
          sheet.cell("Expected results").value = step.expected_results.to_s
        end
      end
      sheet.nextRow
    end

    def traverse(node, depth, sheet)
      sheet.cell("Id").value           = node[:id]
      sheet.cell("Node type id").value = node[:node_type_id]
      sheet.cell(2+depth).value        = node[:name]
      sheet.cell("Keywords").value     = node[:keywords]
      write_node(node, sheet)
      (node[:children] || []).each do |child|
        traverse(child, depth+1, sheet)
      end
    end

    def convert(nodes, prefix='node')
      level = 1
      node_map = {}
      jstree_nodes = []

      for node in nodes
        jstree_node = {
          :id => node.id,
          :node_type_id => node.node_type_id,
          :name => node.name,
          :keywords => node.keywords.map{|keyword| keyword.keyword}.join(","),
          :children=>[],
        }
        level = [node.level, level].max if node.respond_to? :level
        node_map[node.id] = jstree_node
        if node_map.include? node.parent_id
          # non-root node
          node_map[node.parent_id][:children] << jstree_node
        else
          #root node
          jstree_nodes << jstree_node
        end
      end
      [jstree_nodes, level]
    end

  end
end
