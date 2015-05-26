require_dependency 'versions_controller'

module ImpasseVersionsControllerPatch
  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)

    base.class_eval do
      alias_method_chain :destroy, :impasse
    end

  end

  module InstanceMethods
    def destroy_with_impasse
      test_plans = Impasse::TestPlan.find_by(:version_id => @version.id)
      if test_plans
        respond_to do |format|
          format.html {
            flash[:error] = l(:notice_unable_delete_version) << l(:notice_delete_test_plans_first)
            redirect_to :controller => 'projects', :action => 'settings', :tab => 'versions', :id => @project
          }
          format.api  { head :unprocessable_entity }
        end
      else
        destroy_without_impasse
      end
    end
  end
end

