module Impasse
  class TestStep < ActiveRecord::Base
    unloadable
    self.table_name = "impasse_test_steps"

    #attr_accessor :actions, :step_number, :expected_results

    belongs_to :test_case
    
    validates_presence_of :actions, :expected_results

    if Rails::VERSION::MAJOR < 3 or (Rails::VERSION::MAJOR == 3 and Rails::VERSION::MINOR < 1)
      def dup
        clone
      end
    end

  end
end
