# encoding: utf-8

module ImpasseCommonHelper
  unloadable

  TABS = [{:name => 'basic', :url => { :controller => :impasse_test_plans, :action => :show}, :label => :label_general},
          {:name => 'tc_assign', :url => { :controller => :impasse_test_plans, :action => :tc_assign},:label => :label_tc_assign},
          {:name => 'user_assign', :url => { :controller => :impasse_test_plans, :action => :user_assign}, :label => :label_user_assign},
          {:name => 'execution', :url => { :controller => :impasse_executions, :action => :index}, :label => :label_execution},
          {:name => 'statistics', :url => { :controller => :impasse_test_plans, :action => :statistics}, :label => :label_statistics}
         ]

  def render_impasse_tabs
    render :partial => 'impasse_common/impasse_tabs', :locals => { :tabs => TABS }
  end

  def impasse_breadcrumb(*args)
    elements = args.flatten
    if Rails::VERSION::MAJOR < 3
      elements.any? ? content_tag('p', args.join(" \xc2\xbb "), :class => 'breadcrumb') : nil
    else
      elements.any? ? content_tag('p', args.join(" \xc2\xbb ").html_safe, :class => 'breadcrumb') : nil
    end
  end
end
