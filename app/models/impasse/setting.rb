module Impasse
  class Setting < ActiveRecord::Base
    unloadable
    set_table_name "impasse_settings"

    serialize :requirement_tracker

    def can_manage_requirements?
      requirement_tracker and requirement_tracker.any? {|e| e != "" }
    end
  end
end
