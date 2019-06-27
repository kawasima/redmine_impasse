class ImpasseTestPlansController < ImpasseAbstractController
  unloadable

  helper :projects
  include ProjectsHelper

  helper :custom_fields
  include CustomFieldsHelper

  menu_item :impasse
  before_action :find_project_by_project_id, :authorize

  def index
    plan_params = params.permit!.to_h
    @test_plans_by_version, @versions = Impasse::TestPlan.find_all_by_version(@project, plan_params[:completed])
  end

  def show
    plan_params = params.permit!.to_h
    @test_plan = Impasse::TestPlan.where(:id => plan_params[:id]).includes(:version).first
    @setting = Impasse::Setting.find_by(:project_id => @project) || Impasse::Setting.create(:project_id => @project.id)
  end

  def new
    plan_params = params.permit!.to_h
    @test_plan = Impasse::TestPlan.new(plan_params[:test_plan])
    if (request.post? or request.patch?) and @test_plan.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to :action => :tc_assign, :project_id => @project, :id => @test_plan
    end
    @versions = @project.versions
  end

  def edit
    plan_params = params.permit!.to_h
    @test_plan = Impasse::TestPlan.find(plan_params[:id])
    @test_plan.update_attributes(plan_params[:test_plan]) if plan_params.include? :test_plan
    if (request.post? or request.put? or request.patch?) and @test_plan.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to :action => :show, :project_id => @project, :id => @test_plan
    end
    @versions = @project.versions
  end

  def destroy
    plan_params = params.permit!.to_h
    @test_plan = Impasse::TestPlan.find(plan_params[:id])
    if (request.post? or request.patch?) and @test_plan.destroy
      flash[:notice] = l(:notice_successful_delete)
      redirect_to :action => :index, :project_id => @project
    end
  end

  def copy
    plan_params = params.permit!.to_h
    @test_plan = Impasse::TestPlan.find(plan_params[:id])
    @test_plan.update_attributes(plan_params[:test_plan])
    if request.post? or request.put? or request.patch?
      ActiveRecord::Base.transaction do
        new_test_plan = @test_plan.dup
        new_test_plan.save!

        test_plan_cases = Impasse::TestPlanCase.find_all_by_test_plan_id(plan_params[:id])
        for test_plan_case in test_plan_cases
          Impasse::TestPlanCase.create(:test_plan_id => new_test_plan.id, :test_case_id => test_plan_case.test_case_id)
        end
        flash[:notice] = l(:notice_successful_update)
        redirect_to :action => :show, :project_id => @project, :id => new_test_plan
      end
    end
    @versions = @project.versions
  end

  def tc_assign
    params[:tab] = 'tc_assign'
    @versions = @project.versions
    @test_plan = Impasse::TestPlan.find(params[:id])
  end

  def user_assign
    params[:tab] = 'user_assign'
    @versions = @project.versions
    @test_plan = Impasse::TestPlan.find(params[:id])
  end

  def statistics
    @test_plan = Impasse::TestPlan.find(params[:id])
    params[:tab] = 'statistics'
    if params.include? :type
      @statistics = Impasse::Statistics.__send__("summary_#{params[:type]}", @test_plan.id, params[:test_suite_id])
    else
      params[:type] = "default"
      @statistics = Impasse::Statistics.summary_default(@test_plan.id, params[:test_suite_id])
    end

    respond_to do |format|
      if request.xhr?
        format.html { render :partial => "impasse_test_plans/statistics/#{params[:type]}" }
      else
        format.html
      end
      format.json_impasse { render :json => @statistics }
    end
  end

  def add_test_case
    if params.include? :test_case_ids
      new_cases = 0
      nodes = Impasse::Node.where("id in (?)", params[:test_case_ids])
      ActiveRecord::Base.transaction do
        for node in nodes
          test_case_ids = []
          if node.is_test_suite?
            test_case_ids.concat node.all_decendant_cases.collect{|n| n.id}
          else
            test_case_ids << node.id
          end

          for test_case_id in test_case_ids
            test_plan_case =
              Impasse::TestPlanCase.find_or_create_by(:test_case_id => test_case_id,
                                                                                    :test_plan_id => params[:test_plan_id],
                                                                                    :node_order => 0)
            new_cases += 1
          end
        end
      end
    end

    render :json => { :status => 'success', :message => l(:notice_successful_create) }
  end

  def remove_test_case
    Impasse::TestPlanCase.delete_cascade!(params[:test_plan_id], params[:test_case_id])
    render :json => { :status => 'success', :message => l(:notice_successful_delete) }
  end

  def autocomplete
    @users = @project.users.like(params[:q]).limit(100)
    render :layout => false
  end
end
