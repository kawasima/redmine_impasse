module Impasse
  class TestPlansController < AbstractController
    unloadable

    helper :projects
    include ProjectsHelper

    menu_item :impasse
    before_filter :find_project_by_project_id, :authorize

    def index
      @test_plans_by_version, @versions = TestPlan.find_all_by_version(@project)
    end

    def new
      @test_plan = TestPlan.new(params[:test_plan])
      if request.post? and @test_plan.save
        flash[:notice] = l(:notice_successful_create)
        redirect_to :action => :tc_assign, :project_id => @project, :id => @test_plan
      end
      @versions = @project.versions
    end

    def show
      @test_plan = TestPlan.find(params[:id])
    end

    def edit
      @test_plan = TestPlan.find(params[:id])
      @test_plan.attributes = params[:test_plan]
      if request.post? and @test_plan.save
        flash[:notice] = l(:notice_successful_create)
        redirect_to :action => :edit, :project_id => @project, :id => @test_plan
      end
      @versions = @project.versions
    end

    def tc_assign
      params[:tab] = 'tc_assign'
      @versions = @project.versions
      @test_plan = TestPlan.find(params[:id])
    end

    def user_assign
      params[:tab] = 'user_assign'
      @versions = @project.versions
      @test_plan = TestPlan.find(params[:id])
    end

    def statistics
      @test_plan = TestPlan.find(params[:id])
      params[:tab] = 'statistics'
      if params.include? :type
        @statistics = Statistics.__send__("summary_#{params[:type]}", @test_plan.id)
      else
        params[:type] = "default"
        @statistics = Statistics.summary_default(@test_plan.id)
      end

      respond_to do |format|
        if request.xhr?
          format.html { render :partial => "impasse/test_plans/statistics/#{params[:type]}" }
        else
          format.html
        end
        format.json {
          res = [[], []]
          remain = 0
          bug = 0
          start_date = Date.today
          @statistics.each{|st|
            start_date = st.execution_date.to_date if !st.execution_date.nil? and st.execution_date.to_date < start_date
            remain += st.total.to_i
          }
          end_date = @test_plan.version.effective_date
          (start_date-1..end_date).each{|d|
            st = @statistics.find{|st| !st.execution_date.nil? and st.execution_date.to_date == d}
            unless st.nil?
              bug += st.ng.to_i
              remain -= st.total.to_i
            end
            res[0] << [ d.to_date, remain ]
            res[1] << [ d.to_date, bug]
          }

          render :json => res
        }
      end
    end

    def add_test_case
      if params.include? :test_case_ids
        new_cases = 0
        nodes = Node.find(:all, :conditions => ["id in (?)", params[:test_case_ids]])
        for node in nodes
          test_case_ids = []
          if node.is_test_suite?
            test_case_ids.concat node.all_decendant_cases.collect{|n| n.id}
          else
            test_case_ids << node.id
          end

          for test_case_id in test_case_ids
            test_plan_case =
              TestPlanCase.find_or_create_by_test_case_id_and_test_plan_id(
                :test_case_id => test_case_id,
                :test_plan_id => params[:test_plan_id],
                :node_order => 0,
                :urgency => 2)
            new_cases += 1
          end
        end
      end

      respond_to do |format|
        format.json { render :json => {'num'=>new_cases} }
      end
    end

    def remove_test_case
      TestPlanCase.delete_cascade!(params[:test_plan_id], params[:test_case_id])
      respond_to do |format|
        format.json { render :json => { :status => true} }
      end
    end
  end
end
