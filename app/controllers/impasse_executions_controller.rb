require 'erb'

class ImpasseExecutionsController < ImpasseAbstractController
  unloadable

  REL = {1=>"test_project", 2=>"test_suite", 3=>"test_case"}

  helper :custom_fields
  include CustomFieldsHelper

  menu_item :impasse
  before_action :find_project_by_project_id, :authorize

  include ActionView::Helpers::AssetTagHelper

  def index
    params[:tab] = 'execution'
    @test_plan = Impasse::TestPlan.find(params[:id])
  end

  def put
    execution_params = params.permit!.to_h
    @node = Impasse::Node.find(execution_params[:test_plan_case][:test_case_id])
    test_case_ids = (@node.is_test_case?) ? [ @node.id ] : @node.all_decendant_cases.collect{|tc| tc.id}
    if execution_params[:execution] and execution_params[:execution][:expected_date]
      execution_params[:execution][:expected_date] = Time.at(execution_params[:execution][:expected_date].to_i)
    end

    status = 'success'
    errors = []
    for test_case_id in test_case_ids
      test_plan_case = Impasse::TestPlanCase.where(
        test_plan_id: execution_params[:test_plan_case][:test_plan_id], test_case_id: test_case_id).first
      next unless test_plan_case
      execution = Impasse::Execution.where(test_plan_case_id: test_plan_case.id).first_or_initialize
      execution.update_attributes(execution_params[:execution])
      if execution_params[:record]
        execution.execution_ts = Time.now.to_datetime
        execution.executor_id = User.current.id
      end

      begin
        ActiveRecord::Base.transaction do
          execution.save!
          if execution_params[:record]
            @execution_history = Impasse::ExecutionHistory.new(execution.attributes)
            @execution_history.save!
          end
        end
      rescue
        errors.concat(execution.errors.full_messages)
      end
    end
    
    if errors.empty?
      render :json => { :status => 'success', :message => l(:notice_successful_update) }
    else
      render :json => { :status => 'error', :message => l(:error_failed_to_update), :errors => errors }
    end
  end

  def destroy
    node = Impasse::Node.find(params[:test_plan_case][:test_case_id])
    test_case_ids = (node.is_test_case?) ? [ node.id ] : node.all_decendant_cases.collect{|tc| tc.id}

    status = true
    for test_case_id in test_case_ids
      test_plan_case = Impasse::TestPlanCase.where(
                         "test_plan_id=? AND test_case_id=?", params[:test_plan_case][:test_plan_id], test_case_id).first
      next if test_plan_case.nil?
      execution = Impasse::Execution.find_by(:test_plan_case_id => test_plan_case.id)
      next if execution.nil?
      execution.tester_id = execution.expected_date = nil
      satus &= execution.save
    end

    render :json => { :status => status }
  end

  def get_list
    nodes = Impasse::Node.find_planned(params[:id], params[:test_plan_id], params[:filters] || {})
    jstree_nodes = convert(nodes, params[:prefix])

    render :json => jstree_nodes
  end

  def edit
    sql = <<-END_OF_SQL
SELECT impasse_executions.*
FROM impasse_executions
WHERE exists (
  SELECT *
  FROM impasse_test_plan_cases AS tpc
  WHERE impasse_executions.test_plan_case_id = tpc.id
    AND tpc.test_plan_id=? AND tpc.test_case_id=?)
END_OF_SQL
    executions = Impasse::Execution.find_by_sql [sql, params[:test_plan_case][:test_plan_id], params[:test_plan_case][:test_case_id]]
    if executions.size == 0
      @execution = Impasse::Execution.new
      @execution.test_plan_case = Impasse::TestPlanCase.find_by(
        :test_plan_id => params[:test_plan_case][:test_plan_id], :test_case_id => params[:test_plan_case][:test_case_id])
    else
      @execution = executions.first
    end
    @execution.update_attributes(params[:execution]) if params[:execution].present?
    @execution_histories = Impasse::ExecutionHistory.where(:test_plan_case_id => @execution.test_plan_case_id).joins(:executor).order("execution_ts DESC")
    if (request.post? or request.patch?) and @execution.save
      render :json => {'status'=>true}
    else
      render :partial=>'edit'
    end
  end

  def convert(nodes, prefix='node')
    node_map = {}
    jstree_nodes = []
    
    for node in nodes
      jstree_node = {
        'attr' => {'id' => "#{prefix}_#{node.id}" , 'rel' => REL[node.node_type_id]},
        'data' => {},
        'children'=>[]}
      jstree_node['data']['title'] = node.name
      if node.node_type_id == 2
        jstree_node['state'] = 'closed'
      end
      assign_text = []
      if node.firstname or node.lastname
        firstname = node.firstname
        lastname  = node.lastname
        assign_text << User.new(:firstname => node.firstname, :lastname => node.lastname).name
      end
      if node.expected_date
        assign_text << format_date(node.expected_date.to_date)
      end
      if assign_text.size > 0
        jstree_node['data']['title'] << " (#{assign_text.join(' ')})"
      end

      jstree_node['data']['icon'] = status_icon(node.status) if node.node_type_id == 3

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

  def status_icon(status)
    icon_dir = Redmine::Utils::relative_url_root + "/plugin_assets/redmine_impasse/stylesheets/images"
    [
     "#{icon_dir}/document-attribute-t.png",
     "#{icon_dir}/tick.png",
     "#{icon_dir}/cross.png",
     "#{icon_dir}/wall-brick.png",
    ][status.to_i]
  end
end
