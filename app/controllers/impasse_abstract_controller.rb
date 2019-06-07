class ImpasseAbstractController < ApplicationController
  unloadable
  def require_login
    if !User.current.logged?
      # Extract only the basic url parameters on non-GET requests
      local_params = params.permit!.to_h
      if request.get?
        url = url_for(local_params)
      else
        url = url_for(:controller => "/params[:controller]", :action => local_params[:action], :id => local_params[:id], :project_id => local_params[:project_id])
      end

      respond_to do |format|
        format.html { redirect_to :controller => "/account", :action => "login", :back_url => url }
        format.atom { redirect_to :controller => "/account", :action => "login", :back_url => url }
        format.xml  { head :unauthorized, 'WWW-Authenticate' => 'Basic realm="Redmine API"' }
        format.js   { head :unauthorized, 'WWW-Authenticate' => 'Basic realm="Redmine API"' }
        format.json { head :unauthorized }
      end
      return false
    end
    true
  end
end
