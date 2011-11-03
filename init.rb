require 'redmine'

Redmine::Plugin.register :redmine_impasse do
  name 'Redmine Impasse plugin'
  author 'kawasima'
  description 'Test management tool integrated Redmine'
  version '0.0.1'
  url 'http://unit8.net/redmine_impasse'
  author_url 'http://unit8.net/'

  project_module :impasse do
    permission :view_testcases, {
      'impasse/test_case' => [:index, :show, :list],
      'impasse/test_plans' => [:index, :show, :list, :tc_assign, :user_assign, :statistics],
      'impasse/executions' => [:index, :get_list]
    }
    permission :manage_testcases, {
      'impasse/test_case' => [:new, :edit, :destroy, :copy],
      'impasse/test_plans' => [:new, :edit, :destroy, :add_test_case, :remove_test_case],
      'impasse/executions' => [:new, :edit, :destroy, :put],
      'impasse/execution_bugs' => [:new, :edit, :destroy]
    },
    :require => :member
  end

  menu :project_menu, :impasse, { :controller=> 'impasse/test_case', :action=>'index' },
  :caption => :label_impasse,
  :param => :project_id
end
