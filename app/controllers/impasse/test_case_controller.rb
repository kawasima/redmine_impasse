module Impasse
  class TestCaseController < AbstractController
    unloadable

    REL = {1=>"test_project", 2=>"test_suite", 3=>"test_case"}

    menu_item :impasse
    before_filter :find_project, :authorize

    def index
      @nodes = Node.find(:all, :conditions => ["name=? and node_type_id=?", @project.name, 1])
    end

    def list
      if params[:node_id].to_i == -1
        root = Node.find_by_name_and_node_type_id(@project.identifier, 1)
        @nodes = Node.find_children(root.id, params[:test_plan_id])
        root.name = get_root_name(params[:test_plan_id]);
        @nodes.unshift(root)
      else
        @nodes = Node.find_children(params[:node_id], params[:test_plan_id])
      end
      jstree_nodes = convert(@nodes, params[:prefix])

      respond_to do |format|
        format.json { render :json => jstree_nodes }
      end
    end

    def new
      new_node

      if request.post? and @node.save
        @test_case.id = @node.id
        if @node.is_test_case? and params.include? :test_steps
          test_steps = params[:test_steps].collect{|i, ts| TestStep.new(ts) }
          @test_case.test_steps.replace(test_steps)
        end
        @test_case.save!

        respond_to do |format|
          format.json { render :json => [@test_case] }
        end
      else
        render :partial => 'new'
      end
    end

    def copy
      nodes = []
      params[:nodes].each do |i,node_params|
        original_node = Node.find(node_params[:original_id])
        original_node[:node_order] = node_params[:node_order]
        node, test_case = copy_node(original_node, node_params[:parent_id])
        test_case.attributes.merge({:name => node.name})
        nodes << node
      end

      respond_to do |format|
        format.json { render :json => nodes }
      end
    end

    def move
      nodes = []
      params[:nodes].each do |i,node_params|
        node, test_case = get_node(node_params)
        save_node(node)
        nodes << node
      end

      respond_to do |format|
        format.json { render :json => nodes }
      end
    end

    def edit
      @node, @test_case = get_node(params[:node])
      @test_case.attributes = params[:test_case]

      if request.post?
        save_node(@node)
        @test_case.save!
        if @node.is_test_case? and params.include? :test_steps
          test_steps = params[:test_steps].collect{|i, ts| TestStep.new(ts) }
          @test_case.test_steps.replace(test_steps)
        end

        respond_to do |format|
          format.json { render :json => [@test_case] }
        end
      else
        render :partial => 'edit'
      end
    end

    def destroy
      params[:node][:id].each do |id|
        @node = Node.find(id)
        case @node.node_type_id
        when 2
          TestSuite.delete(@node.id)
        when 3
          TestCase.delete(@node.id)
        end
      
        Node.delete_all("path like '#{@node.path}%'")
      end

      respond_to do |format|
        format.json { render :json => {:status => true} }
      end
    end

    private
    def new_node
      @node = Node.new(params[:node])

      case params[:node_type]
      when 'test_case'
        @test_case = TestCase.new(params[:test_case])
        @node.node_type_id = 3
      else
        @test_case = TestSuite.new(params[:test_case])
        @node.node_type_id = 2
      end
    end

    def get_node(node_params)
      node = Node.find(node_params[:id])
      node.attributes = node_params

      if node.is_test_case?
        test_case = TestCase.find(node_params[:id])
      else
        test_case = TestSuite.find(node_params[:id])
      end

      [node, test_case]
    end

    def save_node(node)
      old_node = node.clone
      node.save!
      node.update_siblings_order!

      # If node has children, must update the node path of child nodes.
      node.update_child_nodes_path(old_node.path)

    end

    def get_root_name(test_plan_id)
      if test_plan_id.nil?
        @project.name
      else
        test_plan = TestPlan.find(test_plan_id)
        test_plan.name
      end
    end

    def find_project
      begin
        @project = Project.find(params[:project_id])
        @project_node = Node.find(:first, :conditions=>["name=? and node_type_id=?", @project.name, 1])
        if @project_node.nil?
          @project_node = Node.new(:name=>@project.name, :node_type_id=>1, :node_order=>1)
          @project_node.save
        end
      rescue ActiveRecord::RecordNotFound
        render_404
      end
    end

    def copy_node(original_node, parent_id, level=0)
      node = original_node.clone

      if node.is_test_case?
        original_case = TestCase.find(original_node.id, :include => :test_steps)
        test_case = original_case.clone
        original_case.test_steps.each{|ts| test_case.test_steps << ts.clone }
      else
        original_case = TestSuite.find(original_node.id)
        test_case = original_case.clone
      end

      node.parent_id = parent_id
      node.name = "#{l(:button_copy)}_#{node.name}"
      node.save!
      node.update_siblings_order! if level == 0

      test_case.id = node.id
      test_case.save!

      if original_node.is_test_suite?
        original_node.children.each {|child|
          copy_node(child, node.id, level + 1)
        }
      end
      [node, test_case]
    end

    def convert(nodes, prefix='node')
      node_map = {}
      jstree_nodes = []
    
      for node in nodes
        jstree_node = {
          'attr' => {'id' => "#{prefix}_#{node.id}" , 'rel' => REL[node.node_type_id]},
          'data' => { 'title' => node.name },
          'children'=>[]}
        if node.node_type_id != 3
          jstree_node['state'] = 'open'
        end

        node_map[node.id] = jstree_node
        if node_map.include? node.parent_id
          # non-root node
          node_map[node.parent_id]['children'] << jstree_node
        else
          #root node
          jstree_nodes << jstree_node
        end
      end
      jstree_nodes
    end
  end
end
