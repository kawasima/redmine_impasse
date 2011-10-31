module Impasse
  class TestStep < ActiveRecord::Base
    unloadable
    set_table_name "impasse_test_steps"

    belongs_to :test_case
  end
end
