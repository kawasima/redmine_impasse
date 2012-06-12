module Impasse
  class TestStep < ActiveRecord::Base
    unloadable
    set_table_name "impasse_test_steps"

    belongs_to :test_case
    
    validates_presence_of :actions, :expected_results
  end
end
