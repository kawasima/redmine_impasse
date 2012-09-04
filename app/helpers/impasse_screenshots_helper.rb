# encoding: utf-8
module ImpasseScreenshotsHelper
  def create_thumbnail(attachments)
    width  = 100
    height = 100

    for attachment in attachments[:files]
      image = Magick::Image.read(attachment.diskfile).first
      image = image.change_geometry("#{width}x#{height}") do |cols,rows,img|
        img.resize!(cols,rows)
        img.background_color = 'transparent'
        img.extent(width,height,(width-cols)/2,(height-rows)/2)
      end
      image.write thumbnail_file(attachment)
    end
  end

  def thumbnail_file(attachment)
      thumbnail_file = File.join(File.dirname(attachment.diskfile), "impasse_thumbnail",
                                 File.basename(attachment.diskfile, ".*") + "_s" + File.extname(attachment.diskfile))
  end
end
