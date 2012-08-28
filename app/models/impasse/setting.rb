module Impasse
  class Setting < ActiveRecord::Base
    unloadable
    set_table_name "impasse_settings"

    serialize :requirement_tracker
  end
end
