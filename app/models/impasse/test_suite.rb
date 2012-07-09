module Impasse
  class TestSuite < ActiveRecord::Base
    unloadable
    set_table_name "impasse_test_suites"
    belongs_to :node, :foreign_key => :id

    if Rails::VERSION::MAJOR < 3 or (Rails::VERSION::MAJOR == 3 and Rails::VERSION::MINOR < 1)
      def dup
        clone
      end
    end
  end
end
