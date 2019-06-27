module Impasse
  class TestCase < ActiveRecord::Base
    #include Redmine::SafeAttributes

    unloadable
    self.table_name = "impasse_test_cases"
    self.include_root_in_json = false
    
    #attr_accessor :id, :summary, :preconditions, :importance

    has_many :test_steps, :dependent=>:destroy
    belongs_to :node, :foreign_key=>"id"
    has_many :requirement_cases
    has_many :requirement_issues, :through => :requirement_cases

    acts_as_customizable
    acts_as_attachable :view_permission => :view_testcases,
                       :delete_permission => :manage_testcases

    def project
      root_id = node.path.split(/\./)[1].to_i
      root = Impasse::Node.find(root_id)
      Project.find_by(:identifier => root.name)
    end

    if Rails::VERSION::MAJOR < 3 or (Rails::VERSION::MAJOR == 3 and Rails::VERSION::MINOR < 1)
      def dup
        clone
      end
    end
  end
end
