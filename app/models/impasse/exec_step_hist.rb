module Impasse
  class ExecStepHist < ActiveRecord::Base
    unloadable
    set_table_name "impasse_exec_step_hists"
    self.include_root_in_json = false

    belongs_to :test_steps
    belongs_to :test_plan_case
    belongs_to :issue
    belongs_to :author, class_name: "User", foreign_key: "author_id"
    belongs_to :project
    # attr_accessible :title, :body

    validates :project, :author, presence: true

  end
end
