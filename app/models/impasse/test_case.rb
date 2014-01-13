module Impasse
  class TestCase < ActiveRecord::Base
    unloadable
    set_table_name "impasse_test_cases"
    self.include_root_in_json = false
    
    has_many :test_steps, :dependent=>:destroy, :order => "step_number"
    belongs_to :node, :foreign_key=>"id"
    has_many :requirement_cases
    has_many :requirement_issues, :through => :requirement_cases

    acts_as_customizable
    acts_as_attachable :view_permission => :view_files,
                       :delete_permission => :manage_files

    def project
      root_id = node.path.split(/\./)[1].to_i
      root = Impasse::Node.find(root_id)
      Project.find_by_identifier(root.name)
    end

    if Rails::VERSION::MAJOR < 3 or (Rails::VERSION::MAJOR == 3 and Rails::VERSION::MINOR < 1)
      def dup
        clone
      end
    end
  end
end
