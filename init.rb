require 'redmine'
require 'impasse_projects_helper_patch'

if Rails::VERSION::MAJOR < 3
  require 'dispatcher'
  object_to_prepare = Dispatcher
else
  object_to_prepare = Rails.configuration
end

object_to_prepare.to_prepare do
  require_dependency 'impasse_hooks'

  unless ProjectsHelper.included_modules.include? ImpasseProjectsHelperPatch
    ProjectsHelper.send(:include, ImpasseProjectsHelperPatch)
  end
end

Redmine::Plugin.register :redmine_impasse do
  name 'Redmine Impasse plugin'
  author 'kawasima'
  description 'Test management tool integrated Redmine'
  version '1.1.0'
  url 'http://unit8.net/redmine_impasse'
  author_url 'http://unit8.net/'

  project_module :impasse do
    permission :view_testcases, {
      'impasse_test_case' => [:index, :show, :list, :keywords],
      'impasse_test_plans' => [:index, :show, :list, :tc_assign, :user_assign, :statistics],
      'impasse_executions' => [:index, :get_list]
    }
    permission :manage_testcases, {
      'impasse_test_case' => [:new, :edit, :destroy, :copy, :move],
      'impasse_test_plans' => [:new, :edit, :destroy, :add_test_case, :remove_test_case],
      'impasse_executions' => [:new, :edit, :destroy, :put],
      'impasse_execution_bugs' => [:new, :edit, :destroy]
    }, :require => :member

    permission :setting_testcases, {
      'impasse_settings' => [:index, :show, :edit],
    }, :require => :member
  end

  menu :project_menu, :impasse, { :controller => :impasse_test_case, :action => :index },
  :caption => :label_impasse,
  :param => :project_id
end
