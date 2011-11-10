module Impasse
  class ExecutionBugsController < ApplicationController
    unloadable

    menu_item :impasse
    before_filter :find_project_by_project_id, :only => [:new, :create]
    before_filter :check_for_default_issue_status, :only => [:new, :create]
    before_filter :build_new_issue_from_params, :only => [:new, :create]
  
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
    include IssuesHelper

  def new
    setting = Impasse::Setting.find_by_project_id(@project)
    @issue.tracker_id = setting.bug_tracker_id unless setting.bug_tracker_id.nil?

    respond_to do |format|
      format.html { render :partial => 'new' }
    end
  end

  def create
    call_hook(:controller_issues_new_before_save, { :params => params, :issue => @issue })
    @issue.save!

    execution_bug = ExecutionBug.new(:execution_id => params[:execution_bug][:execution_id], :bug_id => @issue.id)
    execution_bug.save!

    flash[:notice] = l(:notice_successful_create)

    respond_to do |format|
      format.json  { render :json => {status => true} }
    end
  end


  def edit
    update_issue_from_params

    @journal = @issue.current_journal

    respond_to do |format|
      format.html { }
      format.xml  { }
    end
  end

  def update
    update_issue_from_params

    if @issue.save_issue_with_child_records(params, @time_entry)
      render_attachment_warning_if_needed(@issue)
      flash[:notice] = l(:notice_successful_update) unless @issue.current_journal.new_record?

      respond_to do |format|
        format.html { redirect_back_or_default({:action => 'show', :id => @issue}) }
        format.api  { head :ok }
      end
    else
      render_attachment_warning_if_needed(@issue)
      flash[:notice] = l(:notice_successful_update) unless @issue.current_journal.new_record?
      @journal = @issue.current_journal

      respond_to do |format|
        format.html { render :action => 'edit' }
        format.api  { render_validation_errors(@issue) }
      end
    end
  end

  def build_new_issue_from_params
    if params[:id].blank?
      @issue = Issue.new
      @issue.copy_from(params[:copy_from]) if params[:copy_from]
      @issue.project = @project
    else
      @issue = @project.issues.visible.find(params[:id])
    end
    @issue.project = @project    # Tracker must be set before custom field values
    @issue.tracker ||= @project.trackers.find((params[:issue] && params[:issue][:tracker_id]) || params[:tracker_id] || :first)
    if @issue.tracker.nil?
      render_error l(:error_no_tracker_in_project)
      return false
    end

    if params[:issue].is_a?(Hash)
      @issue.safe_attributes = params[:issue]
    end
    @issue.start_date ||= Date.today
    @issue.author = User.current
    @priorities = IssuePriority.all
    @allowed_statuses = @issue.new_statuses_allowed_to(User.current, true)
  end

  def check_for_default_issue_status
    if IssueStatus.default.nil?
      render_error l(:error_no_default_issue_status)
      return false
    end
  end
end
end
