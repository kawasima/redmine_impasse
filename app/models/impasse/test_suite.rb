module Impasse
  class TestSuite < ActiveRecord::Base
    unloadable
    self.table_name = "impasse_test_suites"
    self.include_root_in_json = false

    belongs_to :node, :foreign_key => :id

    acts_as_customizable

    if Rails::VERSION::MAJOR < 3 or (Rails::VERSION::MAJOR == 3 and Rails::VERSION::MINOR < 1)
      def dup
        clone
      end
    end
  end
end
