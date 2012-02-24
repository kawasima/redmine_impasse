require_dependency 'projects_helper'

module Redmine
  module MenuManager
    module MenuHelper
      def render_single_menu_node(item, caption, url, selected)
        if url.instance_of? Hash and url.include? :controller
          url = url.clone
          url[:controller] = "/#{url[:controller]}"
        end
        link_to(h(caption), url, item.html_options(:selected => selected))
      end
    end
  end
end

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
