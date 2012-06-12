require 'redmine'
require 'impasse_projects_helper_patch'
require 'dispatcher'

Dispatcher.to_prepare :redmine_impasse do
  require_dependency 'impasse_hooks'

  unless ProjectsHelper.included_modules.include? ImpasseProjectsHelperPatch
    ProjectsHelper.send(:include, ImpasseProjectsHelperPatch)
  end
end

Redmine::Plugin.register :redmine_impasse do
  name 'Redmine Impasse plugin'
  author 'kawasima'
  description 'Test management tool integrated Redmine'
  version '0.0.1'
  url 'http://unit8.net/redmine_impasse'
  author_url 'http://unit8.net/'

  project_module :impasse do
    permission :view_testcases, {
      'impasse/test_case' => [:index, :show, :list, :keywords],
      'impasse/test_plans' => [:index, :show, :list, :tc_assign, :user_assign, :statistics],
      'impasse/executions' => [:index, :get_list]
    }
    permission :manage_testcases, {
      'impasse/test_case' => [:new, :edit, :destroy, :copy, :move],
      'impasse/test_plans' => [:new, :edit, :destroy, :add_test_case, :remove_test_case],
      'impasse/executions' => [:new, :edit, :destroy, :put],
      'impasse/execution_bugs' => [:new, :edit, :destroy]
    }, :require => :member

    permission :setting_testcases, {
      'impasse/settings' => [:index, :show, :edit],
    }, :require => :member
  end

  menu :project_menu, :impasse, { :controller=> 'impasse/test_case', :action=>'index' },
  :caption => :label_impasse,
  :param => :project_id
end
