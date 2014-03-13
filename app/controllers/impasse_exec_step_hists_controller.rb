class ImpasseExecStepHistsController < ImpasseAbstractController
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
  
# @execution_bug_step.methods => [:inspect, :to_s, :to_a, :to_ary, :frozen?, :==, :eql?, :hash, :[], :[]=, :at, :fetch, :first, :last, :concat, :<<, 
# :push, :pop, :shift, :unshift, :insert, :each, :each_index, :reverse_each, :length, :size, :empty?, 
# :find_index, :index, :rindex, :join, :reverse, :reverse!, 
# :rotate, :rotate!, 
# :sort, :sort!, :sort_by!,
 # :collect, :collect!, 
 # :map, :map!, 
 # :select, :select!,
  # :keep_if, :values_at, 
  # :delete, :delete_at, :delete_if, 
  # :reject, :reject!, 
  # :zip, :transpose, 
  # :replace, :clear, :fill, :include?, :<=>, :slice, :slice!, :assoc, :rassoc, :+, :*, :-, :&, :|, :uniq, :uniq!, :compact, :compact!, :flatten, :flatten!, :count, 
  # :shuffle!, :shuffle, :sample, :cycle, :permutation, :combination, :repeated_permutation, 
  # :repeated_combination, :product, :take, :take_while, :drop, :drop_while, :pack, :extract_options!, 
  # :blank?, :to_sentence, :to_formatted_s, :to_default_s, :to_xml, :uniq_by, :uniq_by!,
   # :to_param, :to_query, :from, :to, :second, :third, :fourth, :fifth, :forty_two, :in_groups_of, :in_groups, :split,
    # :append, :prepend, :to_json, :as_json, :encode_json, :dclone, :shelljoin, :to_csv, 
    # :to_ber, :to_ber_sequence, :to_ber_set, :to_ber_appsequence, :to_ber_contextspecific, :to_ber_oid, :diff, :reverse_hash, 
    # :replacenextlarger, :patch, :entries, :sort_by, :grep, :find, :detect, :find_all, :flat_map, :collect_concat, :inject, 
    # :reduce, :partition, :group_by, :all?, :any?, :one?, :none?, :min, :max, :minmax, :min_by, :max_by, :minmax_by, 
    # :member?, :each_with_index, :each_entry, :each_slice, :each_cons, :each_with_object, :chunk, :slice_before, :to_set, 
    # :sum, :index_by, :many?, :exclude?, :psych_to_yaml, :to_yaml_properties, :to_yaml, :in?, :present?, :presence, 
    # :acts_like?, :try, :html_safe?, :duplicable?, :`, :instance_values, :instance_variable_names, :with_options, 
    # :require_or_load, :require_dependency, :require_association, :load_dependency, :load, :require, :unloadable, :nil?, :===, :=~, :!~, 
    # :class, :singleton_class, :clone, :dup, :initialize_dup, :initialize_clone, :taint, :tainted?, :untaint, :untrust,
     # :untrusted?, :trust, :freeze, :methods, :singleton_methods, :protected_methods, :private_methods,
      # :public_methods, :instance_variables, :instance_variable_get, :instance_variable_set, 
      # :instance_variable_defined?, :instance_of?, :kind_of?, :is_a?, :tap, :send, :public_send,
       # :respond_to?, :respond_to_missing?, :extend, :display, :method, :public_method, 
       # :define_singleton_method, :object_id, :to_enum, :enum_for, :gem, :silence_warnings,
        # :enable_warnings, :with_warnings, :silence_stderr, :silence_stream, :suppress, :capture, :silence, :quietly,
         # :class_eval, :debugger, :breakpoint, :suppress_warnings, :equal?, :!, :!=, :instance_eval, :instance_exec, :__send__, :__id__]

  def create
    call_hook(:controller_issues_new_before_save, { :params => params, :issue => @issue })
        
    if @issue.save
      @execution_bug_step = Impasse::ExecStepHist.new
    #  @execution_bug_step.attributes[:test_steps_id] = params[:execution_bug_step][:test_step_id]
    #  @execution_bug_step.attributes[:project_id] = @project.id
    #  @execution_bug_step.project
      
      @execution_bug_step.project = @project
      @execution_bug_step.author = User.current
      @execution_bug_step.execution_ts = Time.now.to_datetime
      @execution_bug_step.executor_id = User.current.id
      @execution_bug_step.test_steps_id = params[:execution_bug_step][:test_step_id]
    #  @execution_bug_step.test_plan_case_id = 
      
 # @execution_bug_step.attributes =>
      # {"id"=>nil,
      # "test_steps_id"=>nil,
      # "test_plan_case_id"=>nil,
      # "issue_id"=>nil,
      # "author_id"=>0,
      # "project_id"=>0,
      # "tester_id"=>nil,
      # "build_id"=>nil,
      # "expected_date"=>nil,
      # "status"=>nil,
      # "execution_ts"=>nil,
      # "executor_id"=>nil,
      # "created_at"=>nil,
      # "updated_at"=>nil
      #  
      puts "
      
      
      @project ===> #{@project.id}
      
      sdasdasdadadas 
      
      @execution_bug_step.attributes => #{@execution_bug_step.attributes} 
          
      "
      #execution_bug = self.new(:execution_id => params[:execution_bug][:execution_id], :bug_id => @issue.id)
     
     @execution_bug_step.save!
      #execution_bug = self.new(:execution_id => params[:execution_bug][:execution_id], :bug_id => @issue.id)
     
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
end