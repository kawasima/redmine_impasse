if Rails::VERSION::MAJOR < 3
  ActionController::Routing::Routes.draw do |map|
    map.connect 'projects/:project_id/impasse/test_case/:action/:id', :controller=>:impasse_test_case
    map.connect 'projects/:project_id/impasse/test_plans/:action/:id', :controller=>:impasse_test_plans
    map.connect 'projects/:project_id/impasse/executions/:action/:id', :controller=>:impasse_executions
    map.connect 'projects/:project_id/impasse/execution_bugs/:action/:id', :controller=>:impasse_execution_bugs
    map.connect 'projects/:project_id/impasse/settings/:action/:id', :controller=>:impasse_settings
  end
else
  match 'projects/:project_id/impasse/test_case/(:action(/:id))', :controller => 'impasse_test_case'
  match 'projects/:project_id/impasse/test_plans/(:action(/:id))', :controller => 'impasse_test_plans'
  match 'projects/:project_id/impasse/executions/(:action(/:id))', :controller => 'impasse_executions'
  match 'projects/:project_id/impasse/execution_bugs/(:action(/:id))', :controller => 'impasse_execution_bugs'
  match 'projects/:project_id/impasse/settings/(:action(/:id))', :controller => 'impasse_settings'
end
