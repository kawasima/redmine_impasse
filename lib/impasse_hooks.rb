module ImpassePlugin
  class Hook < Redmine::Hook::ViewListener
 
    include IssuesHelper

    def exception(context, ex)
      context[:controller].send(:flash)[:error] = "Impasse error: #{ex.message} (#{ex.class})"
      if Rails::VERSION::MAJOR < 3
        RAILS_DEFAULT_LOGGER.error "#{ex.message} (#{ex.class}): " + ex.backtrace.join("\n")
      else
        Rails.logger.error "#{ex.message} (#{ex.class}): " + ex.backtrace.join("\n")
      end
    end

    def view_issues_show_details_bottom(context={ })
      begin
        issue = context[:issue]

        return '' unless issue.project.module_enabled? 'impasse'

        project = context[:project]
        snippet = ''
  
        setting = Impasse::Setting.find_by(:project_id => project.id) || Impasse::Setting.create(:project_id => project.id)

        if setting.bug_tracker_id == issue.tracker_id
          snippet << show_execution_bugs(issue, project)
        end
        if setting.requirement_tracker and setting.requirement_tracker.include? issue.tracker_id.to_s
          snippet << show_num_of_cases(issue, project)
        end

        return snippet
      rescue => e
        exception(context, e)
        return ''
      end
    end

    def view_issues_show_description_bottom(context = {})
      begin
        issue = context[:issue]

        return '' unless issue.project.module_enabled? 'impasse'

        project = context[:project]
        snippet = ''
  
        setting = Impasse::Setting.find_by(:project_id => project.id) || Impasse::Setting.create(:project_id => project.id)
        if setting.requirement_tracker and setting.requirement_tracker.include? issue.tracker_id.to_s
          snippet << show_requirement_cases(issue, project)
        end
        return snippet
      rescue => e
        exception(context, e)
        return ''
      end        
    end

    def view_issues_form_details_bottom(context = {})
      begin
        snippet = ''
        issue = context[:issue]
        return '' unless issue.project && !issue.project.blank? && issue.project.module_enabled?('impasse')

        project = context[:project]
        return '' unless project && project.blank? && project.module_enabled?('impasse')
        
        setting = Impasse::Setting.find_by(:project_id => project.id) || Impasse::Setting.create(:project_id => project.id)

        if setting.requirement_tracker
          style = (setting.requirement_tracker.include? issue.tracker_id.to_s) ? '' : 'style="display: none;"'
          req_tracker_ids = "[#{setting.requirement_tracker.select{|e| e != "" }.join(',')}]"
          @requirement_issue = Impasse::RequirementIssue.find_by(:issue_id => issue.id)
          snippet << "<p #{style}>" <<
            "<label>#{l(:field_num_of_cases)}</label>" <<
            text_field('requirement_issue', 'num_of_cases', :size => 3) << '</p>' << %{
              <script>
                new Form.Element.EventObserver('issue_tracker_id', function(element, value) {
                if ($A(#{req_tracker_ids}).indexOf(Number(value)) >= 0)
                  $('requirement_issue_num_of_cases').up().show();
                else
                  $('requirement_issue_num_of_cases').up().hide();
                });
              </script>
            }
        end

        return snippet
      rescue => e
        exception(context, e)
        return ''
      end

    end

    def controller_issues_new_after_save(context={ })
      params = context[:params]
      issue = context[:issue]

      setting = Impasse::Setting.find_by(:project_id => issue.project.id) || Impasse::Setting.create(:project_id => issue.project.id)
      if setting.requirement_tracker and setting.requirement_tracker.include? issue.tracker_id.to_s
        num_of_cases = params[:requirement_issue] && params[:requirement_issue][:num_of_cases].to_i || 0
        requirement = Impasse::RequirementIssue.new(:issue_id => issue.id)
        requirement.num_of_cases = num_of_cases
        requirement.save!
      end
    end
    
    def controller_issues_edit_after_save(context={ })
      params = context[:params]
      issue = context[:issue]

      if params[:requirement_issue]
        requirement = Impasse::RequirementIssue.find_by(:issue_id => issue.id) || Impasse::RequirementIssue.new(:issue_id => issue.id)
        requirement.num_of_cases = params[:requirement_issue][:num_of_cases].to_i
        requirement.save!
      end
    end

    private
    def show_execution_bugs(issue, project)
      execution_bug = Impasse::ExecutionBug.where(:bug_id => issue.id).joins(:execution => { :test_plan_case => :test_plan}).first
        
      if execution_bug and execution_bug.execution and execution_bug.execution.test_plan_case
        test_plan_case = execution_bug.execution.test_plan_case
        link_option = link_to(test_plan_case.test_case.node.name, {
                                                             :controller => :impasse_executions,
                                                             :action => :index,
                                                             :project_id => project,
                                                             :id => test_plan_case.test_plan.id,
                                                             :anchor => "testcase-#{test_plan_case.test_case.id}"
                                                         })
        return issue_fields_rows do |row|
          row.left l(:field_test_case), link_option, :class => 'num_of_cases'
        end
      end
      ''
    end

    def show_num_of_cases(issue, project)
      requirement = Impasse::RequirementIssue.find_by(:issue_id => issue.id)
      num_of_cases = requirement ? requirement.num_of_cases : 0

      issue_fields_rows do |rows|
       rows.left l(:field_num_of_cases), num_of_cases.to_s, :class => 'num_of_cases' 
      end
    end

    def show_requirement_cases(issue, project)
      requirement = Impasse::RequirementIssue.where(:issue_id => issue.id).includes(:test_cases).first
      snippet = ''
      if requirement and requirement.test_cases
        snippet << "<hr/><p><strong>#{l(:label_test_case_plural)}</strong></p><table class=\"list\">"
        for test_case in requirement.test_cases
          snippet <<
            "<tr><td>" <<
            link_to(test_case.node.name, {
                      :controller => :impasse_test_case,
                      :action => :index,
                      :project_id => project,
                      :anchor => "testcase-#{test_case.id}"
                    }) <<
            "</td></tr>"
          
        end
        snippet << "</table>"
      end
      snippet
    end
  end
end
