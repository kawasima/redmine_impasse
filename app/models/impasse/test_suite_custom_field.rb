module Impasse
  class TestSuiteCustomField < CustomField
    unloadable
    self.store_full_sti_class = true

    def type_name
      :label_test_suite_plural
    end
  end
end
