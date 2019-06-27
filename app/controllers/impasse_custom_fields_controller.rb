class ImpasseCustomFieldsController < ImpasseAbstractController
  unloadable

  helper CustomFieldsHelper
  helper ImpasseSettingsHelper

  before_action :require_admin

  def index
    @custom_fields_by_type = CustomField.all.group_by {|f| f.class.name }
    @tab = params[:tab] || 'Impasse::TestCaseCustomField'
  end

  def new
    @custom_field = begin
      if params[:type].to_s.match(/.+CustomField$/)
        params[:type].to_s.constantize.new(params[:custom_field])
      end
    rescue
    end
    (redirect_to(:action => 'index'); return) unless @custom_field.is_a?(CustomField)
    if (request.post? or request.patch?) and @custom_field.save
      flash[:notice] = l(:notice_successful_create)
      call_hook(:controller_custom_fields_new_after_save, :params => params, :custom_field => @custom_field)
      redirect_to :action => 'index', :tab => @custom_field.class.name
    else
      @trackers = Tracker.all.order(:position)
    end
  end

  def edit
    @custom_field = CustomField.find(params[:id])
    if (request.post? || request.put? or request.patch?) and @custom_field.update_attributes(params[:custom_field])
      flash[:notice] = l(:notice_successful_update)
      call_hook(:controller_custom_fields_edit_after_save, :params => params, :custom_field => @custom_field)
      redirect_to :action => 'index', :tab => @custom_field.class.name
    else
      @trackers = Tracker.all.order(:position)
    end
  end

  def destroy
    @custom_field = CustomField.find(params[:id]).destroy
    redirect_to :action => 'index', :tab => @custom_field.class.name
  rescue
    flash[:error] = l(:error_can_not_delete_custom_field)
    redirect_to :action => 'index'
  end
end
