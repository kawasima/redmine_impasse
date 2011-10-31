module Impasse
  class TestCase < ActiveRecord::Base
    unloadable
    set_table_name "impasse_test_cases"

    has_many :test_steps, :dependent=>:destroy
    belongs_to :node, :foreign_key=>"id"
  end
end
