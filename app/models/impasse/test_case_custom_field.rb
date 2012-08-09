module Impasse
  class TestCaseCustomField < CustomField
    unloadable
    self.store_full_sti_class = true

    def type_name
      :label_test_case_plural
    end
  end
end
