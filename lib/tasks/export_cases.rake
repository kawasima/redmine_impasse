require 'optparse'


namespace :redmine do
  namespace :impasse do
  
    #$FB : ruby class sheet to replace java FileSystemBookManager sheets
    class Sheet
      def initialize()
        @header_indice = Hash.new
        @header = Hash.new
        @rows = Hash.new
        @currRow = 0
        setRow(@currRow)
      end
      
      def setHeaderAtIndice(indice, value)
        i = 0
        while i < indice do
          if !@header.has_key?(i)
            @header[i] = ""
          end
          i+=1
        end
        @header[indice] = value
        @header_indice[value] = indice
      end
      
      def headerIndice(value)
        return @header_indice[value]
      end
      
      def setRow(indice)
        if indice.is_a? Integer 
          i = 0
          while i <= indice do
            if !@rows.has_key?(i)
              @rows[i] = Hash.new
            end
            i+=1
          end
          @currRow = indice
        end
      end
      
      def nextRow
        setRow(@currRow + 1)
      end
      
      def setCellRowValue(indice, value)
        if indice.is_a? Integer 
          i = 0
          while i < indice do
            if !@rows[@currRow].has_key?(i)
              @rows[@currRow][i] = ""
            end
            i+=1
          end
          @rows[@currRow][indice] = value
        end
      end
      
      def save(filename)
        csv_string = Redmine::Export::CSV.generate do |csv|
          headerRow = Array.new
          @header.sort.map do |rowkey, celvalue|
            headerRow << celvalue
          end
          csv << headerRow
          @rows.sort.map do |rowkey, rowvalue|
            curRow = Array.new
            rowvalue.sort.map do |celkey, celvalue|
              curRow << celvalue
            end
            csv << curRow
          end
        end
        File.open(filename, "w+") do |f|
          f.write(csv_string)
        end
      end
    end
    
    
    desc "Export Redmine Impasse test cases."
    task :export => :environment do |t|
      #$FB remove Axebomber dependency
      #if defined? JRUBY_VERSION
      #  require 'java'
      #
      # gem "activerecord-jdbc-adapter"
      # require 'axebomber'
      #
      # java_import "net.unit8.axebomber.manager.impl.FileSystemBookManager"
      # include Axebomber
      #end

      raise "You must set RAILS_ENV" unless ENV["RAILS_ENV"]
      #raise "You must run in jruby" unless defined? JRUBY_VERSION
      
      project = ENV['project'].to_s.strip
      project = nil if project == '' || project == '*'

      output_file = ENV['output'].to_s.strip 
      output_file = "export.csv" if output_file == ""

      root = Impasse::Node.find_by_name_and_node_type_id(project, 1)
      #$FB test project existing
      raise "Project #{project} Not Found" unless root
      puts "Browsing project #{project} tests..."
      nodes = Impasse::Node.find_children(root.id)
      nodes.unshift(root)

      tree, depth = convert(nodes)

      #$FB create simplier sheet
      #manager = FileSystemBookManager.new
      #book = manager.create(output_file)
      #sheet = book.getSheet("testcases");
      sheet = Sheet.new

      #$FB my way to create colums header
      #row = sheet.getRow(0)
      #row.cell(0).value = "Id"
      #row.cell(1).value = "Node type id"
      #row.cell(depth + 1).value = "Details"
      #row.cell(depth + 2).value = "Summary"
      #row.cell(depth + 3).value = "Preconditions"
      #row.cell(depth + 4).value = "Keywords"
      #row.cell(depth + 5).value = "Actions"
      #row.cell(depth + 6).value = "Expected results"
      #sheet.titleRowIndex = 0
      sheet.setHeaderAtIndice(0, "Id")
      sheet.setHeaderAtIndice(1, "Node type id")
      sheet.setHeaderAtIndice(depth + 1, "Details")
      sheet.setHeaderAtIndice(depth + 2, "Summary")
      sheet.setHeaderAtIndice(depth + 3, "Preconditions")
      sheet.setHeaderAtIndice(depth + 4, "Keywords")
      sheet.setHeaderAtIndice(depth + 5, "Actions")
      sheet.setHeaderAtIndice(depth + 6, "Expected results")
      
      puts "Sheet header"
      
      traverse(tree[0], 0, sheet)
      
      puts "Traverse done"

      #$FB my way to save a csv (and not an xlsx)
      #manager.save(book)
      
      sheet.save(output_file)
      
      puts "Saved to #{output_file}"
    end

    def write_node(node, sheet)
      if node[:node_type_id] == 2
        test_suite = Impasse::TestSuite.find(node[:id])
        #$FB my way to set a cell
        #sheet.cell("Details").value = test_suite.details
        sheet.setCellRowValue(sheet.headerIndice("Details"), test_suite.details)
      elsif node[:node_type_id] == 3
        #test_case = Impasse::TestCase.find(:first, :conditions => ["id=?", node[:id]], :include => :test_steps)
        test_case = Impasse::TestCase.where(:id => node[:id]).includes(:test_steps).first
        #$FB my way to set a cell
        #sheet.cell("Summary").value = test_case.summary
        sheet.setCellRowValue(sheet.headerIndice("Summary"), test_case.summary)
        #$FB my way to set a cell
        #sheet.cell("Preconditions").value = test_case.preconditions
        sheet.setCellRowValue(sheet.headerIndice("Preconditions"), test_case.preconditions)
        test_case.test_steps.each_with_index do |step, i|
          sheet.nextRow unless i == 0
          #$FB my way to set a cell
          #sheet.cell("Actions").value = step.actions
          sheet.setCellRowValue(sheet.headerIndice("Actions"), step.actions)
          #$FB my way to set a cell
          #sheet.cell("Expected results").value = step.expected_results.to_s
          sheet.setCellRowValue(sheet.headerIndice("Expected results"), step.expected_results.to_s)
        end
      end
      sheet.nextRow
    end

    def traverse(node, depth, sheet)
      puts "Traversing level #{depth}"
      #$FB my way to set a cell
      #sheet.cell("Id").value = node[:id]
      sheet.setCellRowValue(sheet.headerIndice("Id"), node[:id])
      #$FB my way to set a cell
      #sheet.cell("Node type id").value = node[:node_type_id]
      sheet.setCellRowValue(sheet.headerIndice("Node type id"), node[:node_type_id])
      #$FB my way to set a cell
      #sheet.cell(2+depth).value = node[:name]
      sheet.setCellRowValue(2+depth, node[:name])
      #$FB my way to set a cell
      #sheet.cell("Keywords").value = node[:keywords]
      sheet.setCellRowValue(sheet.headerIndice("Keywords"), node[:keywords])
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
