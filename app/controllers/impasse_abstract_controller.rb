class ImpasseAbstractController < ApplicationController
  unloadable
  def require_login
    if !User.current.logged?
      # Extract only the basic url parameters on non-GET requests
      if request.get?
        url = url_for(params)
      else
        url = url_for(:controller => "/params[:controller]", :action => params[:action], :id => params[:id], :project_id => params[:project_id])
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
