class ImpasseRequirementIssuesController < ImpasseAbstractController
  unloadable

  helper :queries
  include QueriesHelper
  helper :sort
  include SortHelper
  include IssuesHelper

  def index
    @project = Project.find(params[:project_id])
    setting = Impasse::Setting.find_by(:project_id => @project.id)
    params[:set_filter] = true
    params[:fields] ||= []
    params[:fields] << 'tracker_id'
    params[:values] ||= {}
    params[:values][:tracker_id] = setting.requirement_tracker.select{|e| e != ""}
    params[:operators] ||= {}
    params[:operators][:tracker_id] = "="

    retrieve_query
    sort_init(@query.sort_criteria.empty? ? [['id', 'desc']] : @query.sort_criteria)
    sort_update(@query.sortable_columns)

    if @query.valid?
      @limit = per_page_option

      @issue_count = @query.issue_count
      @issue_pages = Paginator.new self, @issue_count, @limit, params['page']
      @offset ||= @issue_pages.current.offset
      @issues = @query.issues(:include => [:assigned_to, :tracker, :priority, :category, :fixed_version],
                              :order => sort_clause,
                              :offset => @offset,
                              :limit => @limit)
      @issue_count_by_group = @query.result_count_by_group

      render :index, :layout => !request.xhr?
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def add_test_case
    ActiveRecord::Base.transaction do
      requirement_issue = Impasse::RequirementIssue.find_by(:issue_id => params[:issue_id]) || Impasse::RequirementIssue.create(:issue_id => params[:issue_id])
      node = Impasse::Node.find(params[:test_case_id])
      if node.is_test_case?
        create_requirement_case(requirement_issue.id, node.id)
      else
        for test_case_node in node.all_decendant_cases
          create_requirement_case(requirement_issue.id, test_case_node.id)
        end
      end

      render :json => { :status => 'success', :message => l(:notice_successful_create) }
    end
  end

  def remove_test_case
    ActiveRecord::Base.transaction do
      requirement_issue = Impasse::RequirementIssue.find(params[:id])
      requirement_cases = requirement_issue.requirement_cases.where(:test_case_id => params[:test_case_id]).first
      requirement_cases.destroy

      render :json => { :status => 'success', :message => l(:notice_successful_delete) }
    end
  end

  private
  def create_requirement_case(requirement_id, test_case_id) 
    Impasse::RequirementCase.find_by(:requirement_id => requirement_id, :test_case_id => test_case_id) || Impasse::RequirementCase.create(:requirement_id => requirement_id, :test_case_id => test_case_id)
  end

end
