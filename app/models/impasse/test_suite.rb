module Impasse
  class TestSuite < ActiveRecord::Base
    unloadable
    set_table_name "impasse_test_suites"
    belongs_to :node, :foreign_key => :id
  end
end
