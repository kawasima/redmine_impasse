class ImpasseTestCaseController < ImpasseAbstractController
  unloadable

  REL = {1=>"test_project", 2=>"test_suite", 3=>"test_case"}
  
  helper :custom_fields
  include CustomFieldsHelper

  menu_item :impasse
  before_filter :find_project, :authorize

  def index
  end

  def list
    if params[:node_id].to_i == -1
      root = Impasse::Node.find_by_name_and_node_type_id(@project.identifier, 1)
      @nodes = Impasse::Node.find_children(root.id, params[:test_plan_id], params[:filters])
      root.name = get_root_name(params[:test_plan_id])
      @nodes.unshift(root)
    else
      @nodes = Impasse::Node.find_children(params[:node_id], params[:test_plan_id], params[:filters])
    end
    jstree_nodes = convert(@nodes, params[:prefix])
    
    respond_to do |format|
      format.json { render :json => jstree_nodes }
    end
  end
  
  def show
    @node, @test_case = get_node(params[:node])

    respond_to do |format|
      format.html { render :partial => 'show' }
    end
  end

  def new
    new_node

    if request.post? or request.put?
      begin
        ActiveRecord::Base.transaction do
          @node.save!
          save_keywords(@node, params[:node_keywords])
          @test_case.id = @node.id
          if @node.is_test_case? and params.include? :test_steps
            @test_steps = params[:test_steps].collect{|i, ts| Impasse::TestStep.new(ts) }
            @test_steps.each{|ts| raise ActiveRecord::RecordInvalid.new(ts) unless ts.valid? }
            @test_case.test_steps.replace(@test_steps)
          end
          @test_case.save!
          respond_to do |format|
            format.json { render :json => { :status => 'success', :message => l(:notice_successful_create), :ids => [@test_case.id] } }
          end
        end
      rescue ActiveRecord::ActiveRecordError => e
        respond_to do |format|
          errors = []
          errors.concat(@node.errors.full_messages).concat(@test_case.errors.full_messages)
          if @test_steps
            @test_steps.each {|test_step|
              test_step.errors.full_messages.each {|msg|
                errors << "##{test_step.step_number} #{msg}"
              }
            }
          end
          format.json { render :json => { :errors => errors }}
        end
      end
    else
      render :partial => "new"
    end
  end

  def copy
    nodes = []
    params[:nodes].each do |i,node_params|
      ActiveRecord::Base.transaction do 
        original_node = Impasse::Node.find(node_params[:original_id])
        original_node[:node_order] = node_params[:node_order]
        node, test_case = copy_node(original_node, node_params[:parent_id])
        test_case.attributes.merge({:name => node.name})
        nodes << node
      end
    end

    respond_to do |format|
      format.json { render :json => nodes }
    end
  end

  def move
    nodes = []
    params[:nodes].each do |i,node_params|
      ActiveRecord::Base.transaction do 
        node, test_case = get_node(node_params)
        save_node(node)
        nodes << node
      end
    end

    respond_to do |format|
      format.json { render :json => nodes }
    end
  end

  def edit
    @node, @test_case = get_node(params[:node])
    @test_case.attributes = params[:test_case]

    if request.post? or request.put?
      begin
        ActiveRecord::Base.transaction do
          save_node(@node)
          @test_case.save!

          save_keywords(@node, params[:node_keywords])

          if @node.is_test_case? and params.include? :test_steps
            @test_steps = params[:test_steps].collect{|i, ts| Impasse::TestStep.new(ts) }
            @test_steps.each{|ts| raise ActiveRecord::RecordInvalid.new(ts) unless ts.valid? }
            @test_case.test_steps.replace(@test_steps)
          end
          respond_to do |format|
            format.json { render :json => { :status => 'success', :message => l(:notice_successful_update), :ids => [@test_case.id] } }
          end
        end
      rescue ActiveRecord::ActiveRecordError=> e
        respond_to do |format|
          errors = []
          errors.concat(@node.errors.full_messages).concat(@test_case.errors.full_messages)
          if @test_steps
            @test_steps.each {|test_step|
              test_step.errors.full_messages.each {|msg|
                errors << "##{test_step.step_number} #{msg}"
              }
            }
          end
          format.json { render :json => { :errors => errors }}
        end
      end
    else
      render :partial => 'edit'
    end
  end

  def destroy
    params[:node][:id].each do |id|
      node = Impasse::Node.find(id)

      inactive_cases = []
      ActiveRecord::Base.transaction do
        node.all_decendant_cases_with_plan.each do |child|
          if child.planned?
            Impasse::TestCase.update_all({:active => false}, ["id=?", child.id])
            inactive_cases << child
          else
            case child.node_type_id
            when 2
              if inactive_cases.all? {|ic| ! ic.path.start_with? child.path}
                Impasse::TestSuite.delete(id)
                child.destroy
              end
            when 3
              Impasse::TestCase.delete(child.id)
              child.destroy
            end
          end
        end
      end
    end

    respond_to do |format|
      format.json { render :json => {:status => true} }
    end
  end

  def keywords
    keywords = Impasse::Keyword.find_all_by_project_id(@project).map{|r| r.keyword}
    respond_to do |format|
      format.json { render :json => keywords }
    end
  end

  private
  def new_node
    @node = Impasse::Node.new(params[:node])

    case params[:node_type]
    when 'test_case'
      @test_case = Impasse::TestCase.new(params[:test_case])
      @test_case.active = true
      @test_case.importance = 2
      @node.node_type_id = 3
    else
      @test_case = Impasse::TestSuite.new(params[:test_case])
      @node.node_type_id = 2
    end
  end

  def get_node(node_params)
    node = Impasse::Node.find(node_params[:id])
    node.attributes = node_params

    if node.is_test_case?
      test_case = Impasse::TestCase.find(node_params[:id])
    else
      test_case = Impasse::TestSuite.find(node_params[:id])
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

  def save_keywords(node, keywords = "")
    project_keywords = Impasse::Keyword.find_all_by_project_id(@project)
    words = keywords.split(/\s*,\s*/)
    words.delete_if {|word| word =~ /^\s*$/}.uniq!

    node_keywords = node.node_keywords
    keeps = []
    words.each{|word|
      keyword = project_keywords.detect {|k| k.keyword == word}
      if keyword
        node_keyword = node_keywords.detect {|nk| nk.keyword_id == keyword.id}
        if node_keyword
          keeps << node_keyword.id
        else
          new_node_keyword = Impasse::NodeKeyword.create(:keyword_id => keyword.id, :node_id => node.id)
          keeps << new_node_keyword.id
        end
      else
        new_keyword = Impasse::Keyword.create(:keyword => word, :project_id => @project.id)
        new_node_keyword = Impasse::NodeKeyword.create(:keyword_id => new_keyword.id, :node_id => node.id)
        keeps << new_node_keyword.id
      end
    }
    node_keywords.each{|node_keyword|
      node_keyword.destroy unless keeps.include? node_keyword.id
    }
  end

  def get_root_name(test_plan_id)
    if test_plan_id.nil?
      @project.name
    else
      test_plan = Impasse::TestPlan.find(test_plan_id)
      test_plan.name
    end
  end

  def find_project
    begin
      @project = Project.find(params[:project_id])
      @project_node = Impasse::Node.find(:first, :conditions=>["name=? and node_type_id=?", @project.identifier, 1])
      if @project_node.nil?
        @project_node = Impasse::Node.new(:name=>@project.identifier, :node_type_id=>1, :node_order=>1)
        @project_node.save
      end
    rescue ActiveRecord::RecordNotFound
      render_404
    end
  end

  def copy_node(original_node, parent_id, level=0)
    node = original_node.dup

    if node.is_test_case?
      original_case = Impasse::TestCase.find(original_node.id, :include => :test_steps)
      test_case = original_case.dup
      original_case.test_steps.each{|ts| test_case.test_steps << ts.dup }
    else
      original_case = Impasse::TestSuite.find(original_node.id)
      test_case = original_case.dup
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
        'attr' => {'id' => "#{prefix}_#{node.id}" , 'rel' => REL[node.node_type_id] },
        'data' => { 'title' => node.name },
        'children'=>[]}
      if node.node_type_id != 3
        jstree_node['state'] = 'open'
      end
      if node.node_type_id == 3 and !node.active?
        jstree_node['attr']['data-inactive'] = true
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
