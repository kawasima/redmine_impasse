class ImpasseTestCaseController < ImpasseAbstractController
  unloadable

  REL = {1=>"test_project", 2=>"test_suite", 3=>"test_case"}
  
  helper :custom_fields
  include CustomFieldsHelper
  include ImpasseScreenshotsHelper
  include ImpasseTestCaseHelper

  menu_item :impasse
  before_action :find_project, :authorize

  def index
    if User.current.allowed_to?(:move_issues, @project)
      @allowed_projects = Issue.allowed_target_projects_on_move
      @allowed_projects.delete_if{|project| @project.id == project.id }
    end
    @setting = Impasse::Setting.find_by(:project_id => @project) || Impasse::Setting.create(:project_id => @project.id)
    respond_to do |format|
      format.html {
      }
      format.csv  {send_data(export_to_csv(), :type => 'text/csv; header=present', :filename => 'impasse_export.csv')}
    end
  end

  def list
    node_params = params.permit!.to_h
    if node_params[:node_id].to_i == -1
      root = Impasse::Node.find_by(:name => @project.identifier, :node_type_id => 1)
      @nodes = Impasse::Node.find_children(root.id, node_params[:test_plan_id], node_params[:filters])
      root.name = get_root_name(node_params[:test_plan_id])
      @nodes.unshift(root)
    else
      @nodes = Impasse::Node.find_children(node_params[:node_id], node_params[:test_plan_id], node_params[:filters])
    end
    jstree_nodes = convert(@nodes, node_params[:prefix])
    
    render :json => jstree_nodes
  end
  
  def show
    node_params = params.permit!.to_h
    @node, @test_case = get_node(node_params[:node])
    @setting = Impasse::Setting.find_by(:project_id => @project) || Impasse::Setting.create(:project_id => @project.id)

    render :partial => 'show'
  end

  def new
    new_node
    @setting = Impasse::Setting.find_by(:project_id => @project) || Impasse::Setting.create(:project_id => @project.id)

    if request.post? or request.put? or request.patch?
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
          if params[:attachments]
            attachments = Attachment.attach_files(@test_case, params[:attachments])
            create_thumbnail(attachments) if Object.const_defined?(:Magick)
          end
          @test_case.save!
          render :json => { :status => 'success', :message => l(:notice_successful_create), :ids => [@test_case.id] }
        end
      rescue ActiveRecord::ActiveRecordError => e
        errors = []
        errors.concat(@node.errors.full_messages).concat(@test_case.errors.full_messages)
        if @test_steps
          @test_steps.each {|test_step|
            test_step.errors.full_messages.each {|msg|
              errors << "##{test_step.step_number} #{msg}"
            }
          }
        end
        render :json => { :errors => errors }
      end
    else
      render :partial => "new"
    end
  end

  def copy
    nodes_params = params.permit!.to_h
    nodes = []
    nodes_params[:nodes].each do |i,node_params|
      ActiveRecord::Base.transaction do 
        original_node = Impasse::Node.find(node_params[:original_id])
        original_node[:node_order] = node_params[:node_order]
        node, test_case = copy_node(original_node, node_params[:parent_id])
        test_case.attributes.merge({:name => node.name})
        nodes << node
      end
    end

    render :json => nodes
  end

  def move
    node_params = params.permit!.to_h
    nodes = []
    node_params[:nodes].each do |i,nodes|
      ActiveRecord::Base.transaction do 
        node, test_case = get_node(nodes)
        save_node(node)
        nodes << node
      end
    end

    render :json => nodes
  end

  def edit
    node_params = params.permit!.to_h
    @node, @test_case = get_node(node_params[:node])
    @test_case.update_attributes(node_params[:test_case]) if node_params.include? :test_case
    @setting = Impasse::Setting.find_by(:project_id => @project) || Impasse::Setting.create(:project_id => @project.id)

    if request.post? or request.put? or request.patch?
      begin
        ActiveRecord::Base.transaction do
          save_node(@node)
          @test_case.save!
          save_keywords(@node, node_params[:node_keywords])

          if @node.is_test_case? and node_params.include? :test_steps
            @test_steps = node_params[:test_steps].collect{|i, ts| Impasse::TestStep.new(ts) }
            @test_steps.each{|ts| raise ActiveRecord::RecordInvalid.new(ts) unless ts.valid? }
            @test_case.test_steps.replace(@test_steps)
          end

          if node_params[:attachments]
            attachments = Attachment.attach_files(@test_case, node_params[:attachments])
            create_thumbnail(attachments) if Object.const_defined?(:Magick)
          end

          render :json => { :status => 'success', :message => l(:notice_successful_update), :ids => [@test_case.id] }
        end
      rescue ActiveRecord::ActiveRecordError=> e
        errors = []
        errors.concat(@node.errors.full_messages).concat(@test_case.errors.full_messages)
        if @test_steps
          @test_steps.each {|test_step|
            test_step.errors.full_messages.each {|msg|
              errors << "##{test_step.step_number} #{msg}"
            }
          }
        end
        render :json => { :errors => errors }
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
            Impasse::TestCase.where(:id => child.id).update_all(:active => false)
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

    render :json => {:status => true}
  end

  def keywords
    keywords = Impasse::Keyword.where(:project_id => @project).map{|r| r.keyword}
    render :json => keywords
  end

  def copy_to_another_project
    node_params = params.permit!.to_h
    copy_node_ids = []
    dest_project = Project.find(node_params[:dest_project_id])
    node_params[:node_ids].each do |id|
      nodes = Impasse::Node.find_with_children(id)
      for node in nodes
        copy_node_ids[node.level.to_i] ||= {}
        copy_node_ids[node.level.to_i][node.id] = node
      end
      nodes[0].path.split(".").each_with_index do |pid, index|
        next if pid.empty? or pid.to_i == nodes[0].id
        copy_node_ids[index - 1] ||= {}
        copy_node_ids[index - 1][pid.to_i] = nil
      end
    end

    begin
      keyword_hash = {}
      parents = {}
      dest_keywords = Impasse::Keyword.find_all_by_project_id(dest_project.id) || []
      src_keywords  = Impasse::Keyword.find_all_by_project_id(@project.id) || []
      
      for src_keyword in src_keywords
        dest_keyword = dest_keywords.detect {|keyword| keyword.keyword == src_keyword.keyword}
        if dest_keyword
          keyword_hash[dest_keyword.keyword] = dest_keyword.id
        else
          keyword = Impasse::Keyword.create!(:keyword => src_keyword.keyword, :project_id => dest_project.id)
          keyword_hash[keyword.keyword] = keyword.id
        end
      end

      copy_node_ids.each_with_index do |nodes, level|
        nodes.each_pair do |id, node|
          unless node
            node = Impasse::Node.find(id)
          end
          ActiveRecord::Base.transaction do
            new_node = node.dup
            if new_node.node_type_id == 1
              root = Impasse::Node.find_by(:name => dest_project.identifier, :node_type_id => 1)
              if root
                new_node = root
                # TODO get max node order
              else
                new_node.name = dest_project.identifier
              end
            else
              new_node.parent_id = parents[node.parent_id]
            end
            new_node.save!
            parents[node.id] = new_node.id

            case new_node.node_type_id
            when 2
              test_suite = Impasse::TestSuite.find(node.id)
              new_test_suite = test_suite.dup
              new_test_suite.id = new_node.id
              new_test_suite.save!
            when 3
              test_case = Impasse::TestCase.where(:id => node.id).includes(:test_steps).first
              new_test_case = test_case.dup
              new_test_case.id = new_node.id
              new_test_case.save!
              test_case.test_steps.each do |ts|
                attr = ts.attributes
                attr[:test_case_id] = new_test_case._id
                Impasse::TestStep.create!(attr)
              end
            end
            node.node_keywords.map{|nk| Impasse::NodeKeyword.create!(:keyword_id => nk.keyword_id, :node_id => new_node.id) }
          end
        end
      end
      flash[:notice] = l(:notice_successful_create)
      redirect_to :action => :index, :project_id => dest_project
    rescue
      flash[:error] = l(:error_failed_to_update)
      redirect_to :action => :index, :project_id => @project
    end
  end

  private
  def new_node
    node_params = params.permit!.to_h
    @node = Impasse::Node.new(node_params[:node])

    case node_params[:node_type]
    when 'test_case'
      @test_case = Impasse::TestCase.new(node_params[:test_case])
      @test_case.active = true
      @test_case.importance = 2
      @node.node_type_id = 3
    else
      @test_case = Impasse::TestSuite.new(node_params[:test_case])
      @node.node_type_id = 2
    end
  end

  def get_node(node_params)
    node = Impasse::Node.find(node_params[:id])
    node.update_attributes(node_params)

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
    project_keywords = Impasse::Keyword.where(:project_id => @project)
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
      @project_node = Impasse::Node.where(:name => @project.identifier, :node_type_id => 1).first
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
      original_case = Impasse::TestCase.where(:id => original_node.id).includes(:test_steps).first
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
      if node.node_type_id == 2
        jstree_node['state'] = 'closed'
      end
      if node.node_type_id == 3 and !node.active?
        jstree_node['attr']['data-inactive'] = true
      end

      node_map[node.id] = jstree_node
      if node_map.include? node.parent_id
        # non-root node
        node_map[node.parent_id]['children'] << jstree_node
        node_map[node.parent_id]['state'] = 'open'
      else
        #root node
        jstree_nodes << jstree_node
      end
    end
    jstree_nodes
  end

end
