if Rails::VERSION::MAJOR < 3
  ActionController::Routing::Routes.draw do |map|
    map.with_options :namespace => 'impasse' do |impasse|
      impasse.connect 'projects/:project_id/impasse/test_case/:action/:id', :controller=>:test_case
      impasse.connect 'projects/:project_id/impasse/test_plans/:action/:id', :controller=>:test_plans
      impasse.connect 'projects/:project_id/impasse/executions/:action/:id', :controller=>:executions
      impasse.connect 'projects/:project_id/impasse/execution_bugs/:action/:id', :controller=>:execution_bugs
      impasse.connect 'projects/:project_id/impasse/settings/:action/:id', :controller=>:settings
    end
  end
else
  namespace :impasse do
    match 'projects/:project_id/impasse/test_case/:action/:id', :controller=>:test_case
    match 'projects/:project_id/impasse/test_plans/:action/:id', :controller=>:test_plans
    match 'projects/:project_id/impasse/executions/:action/:id', :controller=>:executions
    match 'projects/:project_id/impasse/execution_bugs/:action/:id', :controller=>:execution_bugs
    match 'projects/:project_id/impasse/settings/:action/:id', :controller=>:settings
  end
end
