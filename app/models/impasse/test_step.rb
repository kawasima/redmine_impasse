module Impasse
  class TestStep < ActiveRecord::Base
    unloadable
    set_table_name "impasse_test_steps"

    belongs_to :test_case
    
    validates_presence_of :actions

    if Rails::VERSION::MAJOR < 3 or (Rails::VERSION::MAJOR == 3 and Rails::VERSION::MINOR < 1)
      def dup
        clone
      end
    end

  end
end
