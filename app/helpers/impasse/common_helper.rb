module Impasse
  module CommonHelper
    unloadable

    TABS = [{:name => 'basic', :url=>{:controller=>:test_plans, :action=>:show}, :label => :label_general},
            {:name => 'tc_assign', :url=>{:controller=>:test_plans, :action=>:tc_assign},:label => :label_tc_assign},
            {:name => 'user_assign', :url=>{:controller=>:test_plans, :action=>:user_assign}, :label => :label_user_assign},
            {:name => 'execution', :url=>{:controller=>:executions, :action=>:index}, :label => :label_execution},
            {:name => 'statistics', :url=>{:controller=>:test_plans, :action=>:statistics}, :label => :label_statistics}
           ]

    def render_impasse_tabs
      render :partial => 'impasse/common/impasse_tabs', :locals => { :tabs => TABS }
    end
  end
end
