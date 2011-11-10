require_dependency 'projects_helper'

module ImpasseProjectsHelperPatch
  def self.included(base) # :nodoc:
    base.send(:include, ProjectsHelperMethodsImpasse)

    base.class_eval do
      #unloadable

      alias_method_chain :project_settings_tabs, :impasse
    end

  end
end

module ProjectsHelperMethodsImpasse
  def project_settings_tabs_with_impasse
    tabs = project_settings_tabs_without_impasse
    action = {:name => 'impasse', :controller => 'impasse/settings', :action => :show, :partial => 'impasse/settings/show', :label => :project_module_impasse}

    tabs << action if User.current.allowed_to?(action, @project)

    tabs
  end
end
