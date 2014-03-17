class ImpasseExecStepHistsController < ImpasseAbstractController
  unloadable

  menu_item :impasse
  before_filter :find_project_by_project_id, :only => [:new, :create,:execution_step,:create_step_bug]
  #before_filter :find_project_by_project_id, :authorize
  before_filter :check_for_default_issue_status, :only => [:new, :create, :create_step_bug]
  before_filter :build_new_issue_from_params, :only => [:new, :create, :create_step_bug]

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
  
  
  include ActionView::Helpers::AssetTagHelper
  
  def new
    setting = Impasse::Setting.find_or_create_by_project_id(@project)

    puts "<br><BR>

   metodo NEW

   setting.bug_tracker_id => #{setting.bug_tracker_id}     params = #{params} "

    unless setting.bug_tracker_id.nil?
      unless @project.trackers.find_by_id(setting.bug_tracker_id).nil?
      @issue.tracker_id = setting.bug_tracker_id
      end
    end

    respond_to do |format|
      format.html { render :partial => 'new' }
      format.js   { render :partial => 'issues/attributes' }
    end
  end

  def put
    begin

      paramsExecStepHists = {test_steps_id: null, 
                             test_plan_case_id: null,
                             issue_id: null,
                             author_id: null,
                             project_id: null,
                             tester_id: null,
                             build_id: null,
                             expected_date: null,
                             status: null,
                             executions_ts: null,
                             executor_id: null,
                             created_at: null,
                             updated_at: null}

      ActiveRecord::Base.transaction do
        puts "metodo put

          #{params[:execution]}

          "

        @execution_history_step = Impasse::ExecStepHists.new(params[:execution])

        puts "execution_history_step put

             #{@execution_history_step}

          "
        @execution_history_step.save!
        render :json => { :status => 'success', :message => l(:notice_successful_update) }
      end
    rescue
      puts "

         erro #{@execution_history_step} #{@execution_history_step}

         "
      render :json => { :status => 'error', :message => l(:error_failed_to_update), :errors => @execution_history_step }
    end
  # render_error l(:error_no_default_issue_status)
  # if errors.empty?
  # render :json => { :status => 'success', :message => l(:notice_successful_update) }
  # else
  # render :json => { :status => 'error', :message => l(:error_failed_to_update), :errors => errors }
  # end
  end
  
   def put_step
    begin

      ActiveRecord::Base.transaction do
        puts "metodo put_step

          #{params[:execution]}

          "

        @execution_history_step = Impasse::ExecStepHists.new(params[:execution])

        puts "execution_history_step put

             #{@execution_history_step}

          "
        @execution_history_step.save!
        render :json => { :status => 'success', :message => l(:notice_successful_update) }
      end
    rescue
      puts "

         erro #{@execution_history_step} #{@execution_history_step}

         "
      render :json => { :status => 'error', :message => l(:error_failed_to_update), :errors => @execution_history_step }
    end
  # render_error l(:error_no_default_issue_status)
  # if errors.empty?
  # render :json => { :status => 'success', :message => l(:notice_successful_update) }
  # else
  # render :json => { :status => 'error', :message => l(:error_failed_to_update), :errors => errors }
  # end
  end
    
   def execution_step
      
      @execution_bug_step = Impasse::ExecStepHist.new   
      @execution_bug_step.project = @project
      @execution_bug_step.author = User.current
      @execution_bug_step.execution_ts = Time.now.to_datetime
      @execution_bug_step.executor_id = User.current.id
      @execution_bug_step.test_steps_id = params[:test_steps_id]  
      @execution_bug_step.test_plan_case_id = params[:test_plan_case_id]
      @execution_bug_step.test_plan_case_id = params[:test_case_id]
      @execution_bug_step.status = params[:test_step_status]
         
    if  @execution_bug_step.save  
      #execution_bug = self.new(:execution_id => params[:execution_bug][:execution_id], :bug_id => @issue.id)     
      flash[:notice] = l(:notice_successful_create)
      respond_to do |format|
        format.json  { render :json => { :status => 'success'} }
          #format.json  { render :json => { :status => 'success', :issue_id => @issue.id } }
      end
    else
        respond_to do |format|
        format.json { render :json => { :status => 'error', :errors => @execution_bug_step.errors.full_messages } }
      end
    end
  end

  def create_step_bug
    call_hook(:controller_issues_new_before_save, { :params => params, :issue => @issue })
        
     if @issue.save
      @execution_bug_step = Impasse::ExecStepHist.new    
      @execution_bug_step.project = @project
      @execution_bug_step.author = User.current
      @execution_bug_step.execution_ts = Time.now.to_datetime
      @execution_bug_step.executor_id = User.current.id
      @execution_bug_step.test_steps_id = params[:issue][:test_steps_id]  
      @execution_bug_step.test_plan_case_id = params[:issue][:test_plan_case_id]
      @execution_bug_step.test_plan_case_id = params[:issue][:test_case_id]
      @execution_bug_step.status = params[:issue][:test_step_status]
      @execution_bug_step.issue_id = @issue.id
        
     @execution_bug_step.save!
         
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
    issue = Issue.find(params[:issue_id])
    attachments = Attachment.attach_files(issue, params[:attachments])

    respond_to do |format|
      format.html { render :text => 'ok' }
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
      if Redmine::VERSION::MAJOR == 1 and Redmine::VERSION::MINOR < 4
        if User.current.allowed_to?(:add_issue_watchers, @project) && @issue.new_record?
          @issue.watcher_user_ids = params[:issue]['watcher_user_ids']
        end
      end
    end
    @issue.start_date ||= Date.today
    @issue.author = User.current
    @priorities = IssuePriority.all
    @allowed_statuses = @issue.new_statuses_allowed_to(User.current, true)
    @available_watchers = (@issue.project.users.sort + @issue.watcher_users).uniq
  end

  def check_for_default_issue_status
    if IssueStatus.default.nil?
      render_error l(:error_no_default_issue_status)
    return false
    end
  end
  
  def step_list
    
    # puts "
#     
    # @execution_bug_step => exites?  #{@execution_bug_step}
#     
    # "
    
      sql = <<-END_OF_SQL
             SELECT impasse_exec_step_hists.*, issues.author_id as bug_author_id, 
              issues.subject as bug_subject, 
              issues.description as bug_description,
              issues.status_id, 
              issue_statuses.name as bug_status,
              users.firstname as executor_firstname
              FROM impasse_exec_step_hists 
              left join issues on issues.id = impasse_exec_step_hists.issue_id
              left join issue_statuses on issues.status_id = issue_statuses.id
              left join users on users.id = impasse_exec_step_hists.executor_id
                AND impasse_exec_step_hists.test_steps_id=? 
                and impasse_exec_step_hists.project_id = ?
              END_OF_SQL

    @executionsHist= Impasse::ExecStepHist.find_by_sql [sql, 1,1]
    # puts "<BR><BR> @executionsHist.size =====> #{@executionsHist.size}<BR><BR>
#     
    # executionsHist ===> #{@executionsHist}
    # "
    
   # if executionsHist.size == 0
      #@execution = Impasse::Execution.new
      #@execution.test_plan_case = Impasse::TestPlanCase.find_by_test_plan_id_and_test_case_id(params[:test_plan_case][:test_plan_id], params[:test_plan_case][:test_case_id])
   # else
      #@execution = executions.first
   # end
    #@execution.attributes = params[:execution]
    #@execution_histories = Impasse::ExecutionHistory.find(:all, :joins => [ :executor ], :conditions => ["test_plan_case_id=?", @execution.test_plan_case_id], :order => "execution_ts DESC")
   # if request.post? and @execution.save
   #   render :json => {'status'=>true}
   # else
   #   render :partial=>'edit'
   # end
     # flash[:notice] = l(:notice_successful_create)
      # respond_to do |format|
        # format.json  { render :json => { :status => 'success', :issue_id => 11111 } }
      # end
        render :partial=>'list_edit'
  end
  
end