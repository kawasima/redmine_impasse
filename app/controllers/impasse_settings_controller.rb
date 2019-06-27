class ImpasseSettingsController < ImpasseAbstractController
  unloadable

  before_action :find_project_by_project_id, :authorize

  def index
  end

  def edit
    @setting = Impasse::Setting.find_or_initialize_by(:project_id => @project.id)
    unless params[:setting][:requirement_tracker]
      params[:setting][:requirement_tracker] = []
    end
    @setting.update_attributes(params[:setting])
    if request.put? or request.post? or request.patch?
      ActiveRecord::Base.transaction do
        custom_fields_by_type = {
          'Impasse::TestCaseCustomField'  => [],
          'Impasse::TestSuiteCustomField' => [],
          'Impasse::TestPlanCustomField'  => [],
          'Impasse::ExecutionCustomField' => [],
        }
        (params[:custom_field_ids] || []).each do |custom_field_id|
          custom_field = CustomField.find(custom_field_id)
          custom_fields_by_type[custom_field.type.to_s] << custom_field
        end
        @project.test_case_custom_fields  = custom_fields_by_type['Impasse::TestCaseCustomField']
        @project.test_suite_custom_fields = custom_fields_by_type['Impasse::TestSuiteCustomField']
        @project.test_plan_custom_fields  = custom_fields_by_type['Impasse::TestPlanCustomField']
        @project.execution_custom_fields  = custom_fields_by_type['Impasse::ExecutionCustomField']
        @setting.save!
        flash[:notice] = l(:notice_successful_update)
        redirect_to settings_project_path(@project, :tab => 'impasse')
      end
    end
  end
end
