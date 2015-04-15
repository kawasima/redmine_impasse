if Rails::VERSION::MAJOR < 3
  ActionController::Routing::Routes.draw do |map|
    map.connect 'projects/:project_id/impasse/test_case/:action/:id', :controller => :impasse_test_case
    map.connect 'projects/:project_id/impasse/test_plans/:action/:id', :controller => :impasse_test_plans
    map.connect 'projects/:project_id/impasse/executions/:action/:id', :controller => :impasse_executions
    map.connect 'projects/:project_id/impasse/execution_bugs/:action/:id', :controller => :impasse_execution_bugs
    map.connect 'projects/:project_id/impasse/settings/:action/:id', :controller => :impasse_settings
    map.connect 'projects/:project_id/impasse/requirement_issues/:action/:id', :controller => :impasse_requirement_issues
    map.connect 'projects/:project_id/impasse/screenshots/:attachment_id.:size.:format', :controller => :impasse_screenshots, :action => :show, :attachment_id => /\d+/
    map.connect 'projects/:project_id/impasse/screenshots/:action/:id', :controller => :impasse_screenshots
    map.connect 'impasse/custom_fields/:action/:id', :controller => :impasse_custom_fields
  end
else
  match 'projects/:project_id/impasse/test_case/(:action(/:id))', :controller => 'impasse_test_case', :via => [:get, :post]
  match 'projects/:project_id/impasse/test_plans/(:action(/:id))', :controller => 'impasse_test_plans', :via => [:get, :post]
  match 'projects/:project_id/impasse/executions/(:action(/:id))', :controller => 'impasse_executions', :via => [:get, :post]
  match 'projects/:project_id/impasse/execution_bugs/(:action(/:id))', :controller => 'impasse_execution_bugs', :via => [:get, :post]
  match 'projects/:project_id/impasse/settings/(:action(/:id))', :controller => 'impasse_settings', :via => [:get, :post]
  match 'projects/:project_id/impasse/requirement_issues/(:action(/:id))', :controller => 'impasse_requirement_issues', :via => [:get, :post]
  match 'projects/:project_id/impasse/screenshots/:attachment_id(.:size).:format', :controller => 'impasse_screenshots', :action => 'show', :attachment_id => /\d+/, :via => [:get, :post]
  match 'projects/:project_id/impasse/screenshots/(:action/(:id))', :controller => 'impasse_screenshots', :via => [:get, :post]
  match 'impasse/custom_fields/(:action(/:id))', :controller => 'impasse_custom_fields', :via => [:get, :post]
end
