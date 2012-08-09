module Impasse
  class TestPlanCustomField < CustomField
    unloadable
    self.store_full_sti_class = true

    def type_name
      :label_test_plan_plural
    end
  end
end
