class ImpasseScreenshotsController < ImpasseAbstractController
  unloadable

  include ImpasseScreenshotsHelper

  def new
    @test_case = Impasse::TestCase.find(params[:test_case_id])
    if request.post?
      attachments = Attachment.attach_files(@test_case, {1 => params[:image]})
      create_thumbnail(attachments) if Object.const_defined?(:Magick)
    end
  end

  def show
    @attachment = Attachment.find(params[:attachment_id])
    unless @attachment.readable?
      render_404; return
    end
    unless @attachment.visible?
      deny_access; return
    end
    diskfile = @attachment.diskfile
    if params[:size] and params[:size] == 's'
      thumb = thumbnail_file(@attachment)
      diskfile = thumb if File.exist? thumb
    end
    send_file diskfile, :type => @attachment.content_type, :disposition => 'inline'
  end

  def destroy
    @attachment = Attachment.find(params[:attachment_id])
    @attachment.destroy
    render :json => { :status => 'success' }
  end
end
