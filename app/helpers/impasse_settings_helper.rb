# encoding: utf-8
module ImpasseSettingsHelper
  def impasse_custom_fields_tabs
    [
     {:name => 'Impasse-TestCaseCustomField',  :partial => 'impasse_custom_fields/index', :label => :label_test_case_plural},
     {:name => 'Impasse-TestSuiteCustomField', :partial => 'impasse_custom_fields/index', :label => :label_test_suite_plural},
     {:name => 'Impasse-TestPlanCustomField',  :partial => 'impasse_custom_fields/index', :label => :label_test_plan_plural},
     {:name => 'Impasse-ExecutionCustomField',  :partial => 'impasse_custom_fields/index', :label => :label_execution_plural},
    ]
  end
end
