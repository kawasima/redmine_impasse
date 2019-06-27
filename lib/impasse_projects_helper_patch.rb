require_dependency 'projects_helper'

module ImpasseProjectsHelperPatch
  def self.included(base) # :nodoc:
    base.send(:include, ProjectsHelperMethodsImpasse)
    base.send(:include, ImpasseSettingsHelper)

    base.class_eval do
      #unloadable
      # alias_method_chain :project_settings_tabs, :impasse
    end

  end
end

module ProjectsHelperMethodsImpasse
  def project_settings_tabs
    tabs = super
    action = {:name => 'impasse', :controller => :impasse_settings, :action => :show, :partial => 'impasse_settings/show', :label => :project_module_impasse}

    tabs << action if User.current.allowed_to?(action, @project)

    tabs
  end
end
