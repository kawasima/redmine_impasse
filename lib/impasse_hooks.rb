module ImpassePlugin
  class Hook < Redmine::Hook::ViewListener
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
  
        setting = Impasse::Setting.find_by_project_id(project.id)

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
  
        setting = Impasse::Setting.find_by_project_id(project.id)
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
        
        return '' unless issue.project.module_enabled?('impasse')

        @requirement_issue = Impasse::RequirementIssue.find_by_issue_id(issue.id)
        snippet << '<p>' <<
          "<label>#{l(:field_num_of_cases)}</label>" <<
          text_field('requirement_issue', 'num_of_cases', :size => 3) << '</p>'

        return snippet
      rescue => e
        exception(context, e)
        return ''
      end

    end

    def controller_issues_edit_after_save(context={ })
      params = context[:params]
      issue = context[:issue]
      if params[:requirement_issue]
        requirement = Impasse::RequirementIssue.find_by_issue_id(issue.id)
        requirement.num_of_cases = Integer(params[:requirement_issue][:num_of_cases])
        requirement.save!
      end
    end

    private
    def show_execution_bugs(issue, project)
      execution_bug = Impasse::ExecutionBug.find(:first, :joins => [ { :execution => { :test_plan_case => :test_plan}}  ],
                                                 :conditions => {:bug_id, issue.id})
        
      if execution_bug and execution_bug.execution and execution_bug.execution.test_plan_case
        test_plan_case = execution_bug.execution.test_plan_case
        return "<tr><th>#{l(:field_test_case)}</th><td>" <<
          link_to(test_plan_case.test_case.node.name, {
                    :controller => :impasse_executions,
                    :action => :index,
                    :project_id => project,
                    :id => test_plan_case.test_plan.id,
                    :anchor => "testcase-#{test_plan_case.test_case.id}"
                  }) <<
          "</td></tr>"
      end
      ''
    end

    def show_num_of_cases(issue, project)
      requirement = Impasse::RequirementIssue.find_by_issue_id(issue.id)
      num_of_cases = requirement ? requirement.num_of_cases : 0
      "<tr><th>#{l(:field_num_of_cases)}:</th><td>#{num_of_cases}</td></tr>"
    end

    def show_requirement_cases(issue, project)
      requirement = Impasse::RequirementIssue.find(
        :first, :conditions => { :issue_id => issue.id },
        :include => :test_cases)
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
