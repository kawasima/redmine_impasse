class ImpasseTSEHistsController < ApplicationController
  unloadable
    
  
  respond_to :html, :json
  #respond_to :js, only: [:show, :new_step, :create, :edit, :update, :destroy]

 # before_filter :find_project_by_project_id
 # before_filter :find_impasse_t_s_e_hists, only: [:new_step,:show, :edit, :update, :destroy]
 # before_filter :authorize

  include SortHelper
  helper :sort

  def index
    sort_init "updated_at"
    sort_update %w( created_at updated_at)
    @impasse_t_s_e_hist_pages, @impasse_t_s_e_hists = paginate ImpasseTSEHist.where(project_id: @project).order(sort_clause)
    respond_with @impasse_t_s_e_hists
  end

 def new_step
    setting = Impasse::Setting.find_or_create_by_project_id(@project)
    
    puts "<br><BR> new_step >>>> setting.bug_tracker_id => #{setting.bug_tracker_id}     params = #{params} post => #{@POST}"
    
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

  def show
    respond_with @impasse_t_s_e_hist
  end

  def new
    @impasse_t_s_e_hist = ImpasseTSEHist.new
    respond_with @impasse_t_s_e_hist
  end

  def edit
    respond_with @impasse_t_s_e_hist
  end

  def create
    @impasse_t_s_e_hist = ImpasseTSEHist.new(params[:impasse_t_s_e_hist])
    @impasse_t_s_e_hist.project = @project
    @impasse_t_s_e_hist.author = User.current
    if @impasse_t_s_e_hist.save && !request.xhr?
      flash[:notice] = l(:label_impasse_t_s_e_hist_created)
    end
    respond_with @impasse_t_s_e_hist
  end

  def update
    if @impasse_t_s_e_hist.update_attributes(params[:impasse_t_s_e_hist]) && !request.xhr?
      flash[:notice] = l(:label_impasse_t_s_e_hist_updated)
    end
    respond_with @impasse_t_s_e_hist
  end

  def destroy
    @impasse_t_s_e_hist.destroy
    flash[:notice] = l(:label_impasse_t_s_e_hist_deleted) unless request.xhr?
    respond_with @impasse_t_s_e_hist, location: impasse_t_s_e_hists_path
  end

  # Override url/path convenience methods options to include project
  def url_options
    super.reverse_merge project_id: @project
  end

  private
  def find_impasse_t_s_e_hist
    @impasse_t_s_e_hist = ImpasseTSEHist.find(params[:id])
    render_404 unless @impasse_t_s_e_hist.project_id == @project.id
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
