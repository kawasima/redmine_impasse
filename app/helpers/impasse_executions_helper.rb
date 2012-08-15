# encoding: utf-8
module ImpasseExecutionsHelper
  include ImpasseCommonHelper
  include Redmine::I18n

  STATUS_LABELS = [l(:label_execution_status_0), l(:label_execution_status_1), l(:label_execution_status_2), l(:label_execution_status_3)]

  def format_status(status = 0)
    STATUS_LABELS[status.to_i]
  end
end
