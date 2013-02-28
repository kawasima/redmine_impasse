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

  unless VersionsController.included_modules.include? ImpasseVersionsControllerPatch
    VersionsController.send(:include, ImpasseVersionsControllerPatch)
  end

  Project.class_eval do
    has_and_belongs_to_many :test_case_custom_fields,
    :class_name => 'Impasse::TestCaseCustomField',
    :order => "#{CustomField.table_name}.position",
    :join_table => "#{table_name_prefix}custom_fields_projects#{table_name_suffix}",
    :foreign_key => 'project_id',
    :association_foreign_key => 'custom_field_id'

    has_and_belongs_to_many :test_suite_custom_fields,
    :class_name => 'Impasse::TestSuiteCustomField',
    :order => "#{CustomField.table_name}.position",
    :join_table => "#{table_name_prefix}custom_fields_projects#{table_name_suffix}",
    :foreign_key => 'project_id',
    :association_foreign_key => 'custom_field_id'

    has_and_belongs_to_many :test_plan_custom_fields,
    :class_name => 'Impasse::TestPlanCustomField',
    :order => "#{CustomField.table_name}.position",
    :join_table => "#{table_name_prefix}custom_fields_projects#{table_name_suffix}",
    :foreign_key => 'project_id',
    :association_foreign_key => 'custom_field_id'

    has_and_belongs_to_many :execution_custom_fields,
    :class_name => 'Impasse::ExecutionCustomField',
    :order => "#{CustomField.table_name}.position",
    :join_table => "#{table_name_prefix}custom_fields_projects#{table_name_suffix}",
    :foreign_key => 'project_id',
    :association_foreign_key => 'custom_field_id'  
  end
end

Redmine::Plugin.register :redmine_impasse do
  name 'Redmine Impasse plugin'
  author 'kawasima'
  description 'Test management tool integrated Redmine'
  version '1.2.2'
  url 'http://unit8.net/redmine_impasse'
  author_url 'http://unit8.net/'

  settings :partial => 'redmine_impasse/setting'

  project_module :impasse do
    permission :view_testcases, {
      'impasse_test_case' => [:index, :show, :list, :keywords],
      'impasse_test_plans' => [:index, :show, :list, :tc_assign, :user_assign, :statistics, :autocomplete],
      'impasse_executions' => [:index, :get_list],
      'impasse_requirement_issues' => [:index],
      'impasse_screenshots' => [:show],
    }
    permission :manage_testcases, {
      'impasse_test_case' => [:new, :edit, :destroy, :copy, :move, :copy_to_another_project, :screenshot],
      'impasse_test_plans' => [:new, :edit, :destroy,:copy, :add_test_case, :remove_test_case],
      'impasse_executions' => [:new, :edit, :destroy, :put],
      'impasse_execution_bugs' => [:new, :edit, :destroy, :upload_attachments],
      'impasse_requirement_issues' => [:add_test_case, :remove_test_case],
      'impasse_screenshots' => [:new, :destroy],
    }, :require => :member

    permission :setting_testcases, {
      'impasse_settings' => [:index, :show, :edit],
    }, :require => :member
  end

  menu :project_menu, :impasse, { :controller => :impasse_test_case, :action => :index },
  :caption => :label_impasse,
  :param => :project_id

  Redmine::MenuManager.map :impasse_admin_menu do |menu|
    menu.push :custom_field, {:controller => 'impasse_custom_fields'}, :caption => :label_custom_field_plural,
    :html => {:class => 'custom_fields'}
  end

  Mime::Type.register_alias "application/json", :json_impasse
end

