module Impasse
  class RequirementStats < ActiveRecord::Base
    unloadable
    #dummy table
    self.table_name = "impasse_requirement_stats"

    def self.columns
      @columns ||= [];
    end

    def self.column(name, sql_type = nil, default = nil, null = true)
      columns << ActiveRecord::ConnectionAdapters::Column.new(name.to_s, default,
                                                              sql_type.to_s, null)
    end
    
    def issue_id=(issue_id)
      write_attribute(:issue_id, issue_id.to_i)
    end

    def issue_id
      read_attribute(:issue_id).to_i
    end

    def subject=(subject)
      write_attribute(:subject, subject)
    end

    def subject
      read_attribute(:subject)
    end

    def needed=(needed)
      write_attribute(:needed, needed.to_i)
    end

    def needed
      read_attribute(:needed).to_i
    end

    def actual=(actual)
      write_attribute(:actual, actual.to_i)
    end

    def actual
      read_attribute(:actual).to_i
    end

    def planned=(planned)
      write_attribute(:planned, planned.to_i)
    end

    def planned
      read_attribute(:planned).to_i
    end

    def coverage
      if needed < planned
        100.0
      elsif planned == 0
        0.0
      else
        planned * 100.0 / needed.to_f
      end
    end
  end
end
