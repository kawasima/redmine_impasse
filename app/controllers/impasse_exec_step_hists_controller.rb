class ImpasseExecStepHistsController < ApplicationController
  unloadable
  
#  helper :custom_fields
#  include CustomFieldsHelper
  
  respond_to :html, :json
  respond_to :js, only: [:show, :new, :create, :edit, :update, :destroy]


  menu_item :impasse
  before_filter :find_project_by_project_id, :authorize


#  before_filter :find_project_by_project_id
#  before_filter :find_impasse_exec_step_hist, only: [:new, :show, :edit, :update, :destroy]
#  before_filter :authorize

  include SortHelper
  helper :sort

  def index
    sort_init "updated_at"
    sort_update %w( created_at updated_at)
    @impasse_exec_step_hist_pages, @impasse_exec_step_hists = paginate ImpasseExecStepHist.where(project_id: @project).order(sort_clause)
    respond_with @impasse_exec_step_hists
  end

  def show
    respond_with @impasse_exec_step_hist
  end

  def new
    puts " @impasse_exec_step_hist #{@impasse_exec_step_hist}"
    respond_to do |format|
        format.json { render :json => { :status => 'error', :errors => @issue.errors.full_messages } }
      end
    #@impasse_exec_step_hist = ImpasseExecStepHist.new
    #puts(@impasse_exec_step_hist)
    #respond_with @impasse_exec_step_hist
  end

  def edit
    respond_with @impasse_exec_step_hist
  end

  def create
    @impasse_exec_step_hist = ImpasseExecStepHist.new(params[:impasse_exec_step_hist])
    @impasse_exec_step_hist.project = @project
    @impasse_exec_step_hist.author = User.current
    if @impasse_exec_step_hist.save && !request.xhr?
      flash[:notice] = l(:label_impasse_exec_step_hist_created)
    end
    respond_with @impasse_exec_step_hist
  end

  def update
    if @impasse_exec_step_hist.update_attributes(params[:impasse_exec_step_hist]) && !request.xhr?
      flash[:notice] = l(:label_impasse_exec_step_hist_updated)
    end
    respond_with @impasse_exec_step_hist
  end

  def destroy
    @impasse_exec_step_hist.destroy
    flash[:notice] = l(:label_impasse_exec_step_hist_deleted) unless request.xhr?
    respond_with @impasse_exec_step_hist, location: impasse_exec_step_hists_path
  end

  # Override url/path convenience methods options to include project
  def url_options
    super.reverse_merge project_id: @project
  end

  private
  def find_impasse_exec_step_hist
    @impasse_exec_step_hist = ImpasseExecStepHist.find(params[:id])
    render_404 unless @impasse_exec_step_hist.project_id == @project.id
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
