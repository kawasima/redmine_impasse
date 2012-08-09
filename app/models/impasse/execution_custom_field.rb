module Impasse
  class ExecutionCustomField < CustomField
    unloadable
    self.store_full_sti_class = true

    def type_name
      :label_execution_plural
    end
  end
end
