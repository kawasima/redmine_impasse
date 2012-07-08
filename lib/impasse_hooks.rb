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
  
        snippet = ''
  
        project = context[:project]
        execution_bug = Impasse::ExecutionBug.find_by_bug_id(issue.id)
        test_plan_case = execution_bug.execution.test_plan_case
        
        if execution_bug
          snippet << "<tr><th>#{l(:field_test_case)}</th><td>" <<
            link_to(test_plan_case.test_case.node.name, {
                      :controller => :impasse_executions,
                      :action => :index,
                      :project_id => project,
                      :id => test_plan_case.test_plan.id,
                      :anchor => "testcase-#{test_plan_case.test_case.id}"
                    }) <<
          "</td></tr>"
        end
  
        return snippet
      rescue => e
        exception(context, e)
        return ''
      end
    end

    def controller_issues_edit_after_save(context={ })
      params = context[:params]
      issue = context[:issue]
    end
  end
end
