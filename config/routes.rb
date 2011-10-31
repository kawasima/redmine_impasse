ActionController::Routing::Routes.draw do |map|
#  map.with_options :namespace => 'impasse', :controller => :test_case do |test_case|
#    test_case.connect 'projects/:project_id/impasse/test_case/:action'
#  end

#  map.with_options :namespace => 'impasse', :controller => :test_plans do |test_plan|
#    test_plan.connect 'projects/:project_id/impasse/test_plans/:action/:id'
#  end

#  map.with_options :namespace => 'impasse', :controller => :executions do |execution|
#    execution.connect 'projects/:project_id/impasse/executions/:action'
#  end

#  map.with_options :namespace => 'impasse', :controller => :execution_bugs do |execution_bug|
#    execution_bug.connect 'projects/:project_id/impasse/execution_bugs/:action'
#  end

  map.with_options :namespace => 'impasse' do |impasse|
    impasse.connect 'projects/:project_id/impasse/test_case/:action/:id', :controller=>:test_case
    impasse.connect 'projects/:project_id/impasse/test_plans/:action/:id', :controller=>:test_plans
    impasse.connect 'projects/:project_id/impasse/executions/:action/:id', :controller=>:executions
    impasse.connect 'projects/:project_id/impasse/execution_bugs/:action/:id', :controller=>:execution_bugs
  end
end
