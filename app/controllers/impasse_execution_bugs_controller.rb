class ImpasseExecutionBugsController < ImpasseAbstractController
  unloadable

  menu_item :impasse
  before_action :find_project_by_project_id, :only => [:new, :create]
  before_action :build_new_issue_from_params, :only => [:new, :create]
  
  helper :journals
  helper :projects
  include ProjectsHelper
  helper :custom_fields
  include CustomFieldsHelper
  helper :issue_relations
  include IssueRelationsHelper
  helper :watchers
  include WatchersHelper
  helper :attachments
  include AttachmentsHelper
  helper :queries
  include QueriesHelper
  helper :repositories
  include RepositoriesHelper
  helper :sort
  include SortHelper
  helper :issues
  include IssuesHelper

  def new
    setting = Impasse::Setting.find_or_initialize_by(:project_id => @project)
    @issue.tracker_id = setting.bug_tracker_id unless setting.bug_tracker_id.nil?

    respond_to do |format|
      format.html { render :partial => 'new' }
      format.js   { render :partial => 'issues/attributes' }
    end
  end

  def create
    execution_params = params.permit!.to_h
    call_hook(:controller_issues_new_before_save, { :params => execution_params, :issue => @issue })
    if @issue.save
      execution_bug = Impasse::ExecutionBug.new(:execution_id => execution_params[:execution_bug][:execution_id], :bug_id => @issue.id)
      execution_bug.save!

      flash[:notice] = l(:notice_successful_create)
      respond_to do |format|
        format.json  { render :json => { :status => 'success', :issue_id => @issue.id } }
      end
    else
      respond_to do |format|
        format.json { render :json => { :status => 'error', :errors => @issue.errors.full_messages } }
      end
    end
  end

  def upload_attachments
    execution_params = params.permit!.to_h
    issue = Issue.find(execution_params[:issue_id])
    attachments = Attachment.attach_files(issue, execution_params[:attachments])

    respond_to do |format|
      format.html { render :text => 'ok' }
    end
  end

  def build_new_issue_from_params
    issue_params = params.permit!.to_h

    if issue_params[:id].blank?
      @issue = Issue.new
      @issue.copy_from(issue_params[:copy_from]) if issue_params[:copy_from]
      @issue.project = @project
    else
      @issue = @project.issues.visible.find(issue_params[:id])
    end
    @issue.project = @project    # Tracker must be set before custom field values
    if (issue_params[:issue] && issue_params[:issue][:tracker_id]) || issue_params[:tracker_id]
      @issue.tracker ||= @project.trackers.find((issue_params[:issue] && issue_params[:issue][:tracker_id]) || issue_params[:tracker_id])
    else
      @issue.tracker ||= @project.trackers.first
    end
    if @issue.tracker.nil?
      render_error l(:error_no_tracker_in_project)
      return false
    end

    if issue_params[:issue].is_a?(Hash)
      @issue.safe_attributes = issue_params[:issue]
    end
    @issue.start_date ||= Date.today
    @issue.author = User.current
    @priorities = IssuePriority.all
    @allowed_statuses = @issue.new_statuses_allowed_to(User.current, true)
    @available_watchers = (@issue.project.users.sort + @issue.watcher_users).uniq
  end

end
