module Impasse
  class Setting < ActiveRecord::Base
    unloadable
    self.table_name = "impasse_settings"

    attr_accessible :project_id

    serialize :requirement_tracker

    def can_manage_requirements?
      requirement_tracker and requirement_tracker.any? {|e| e != "" }
    end
  end
end
