module Impasse
  class Keyword < ActiveRecord::Base
    unloadable
    set_table_name "impasse_keywords"

    belongs_to :project
  end
end
