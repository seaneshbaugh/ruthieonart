class Picture < ActiveRecord::Base
  attr_accessible :title, :alt_text, :caption, :image

  has_attached_file :image, { :convert_options => { :thumb => '-quality 75 -strip', :medium => '-quality 85 -strip' },
                              :path => ":rails_root/public/uploads/#{Rails.env.test? ? 'test/' : ''}:class_singular/:attachment/:style_prefix:basename.:extension",
                              :styles => { :thumb => '100x100', :medium => '300x300' },
                              :url => "/uploads/:class_singular/:attachment/#{Rails.env.test? ? 'test/' : ''}:style_prefix:basename.:extension" }

  validates_length_of   :title, :maximum => 65535
  validates_presence_of :title

  validates_length_of :alt_text, :maximum => 65535

  validates_length_of :caption, :maximum => 65535

  validates_uniqueness_of :image_fingerprint, :if => Proc.new { !Rails.env.test? }

  validates_attachment_presence :image
  validates_attachment_size :image, :less_than => 1024.megabytes
  validates_attachment_content_type :image, :content_type => %w(image/gif image/jpeg image/jpg image/pjpeg image/png image/svg+xml image/tiff image/x-png)

  after_initialize do
    if self.new_record?
      self.title ||= ''
      self.alt_text ||= ''
      self.caption ||= ''
      self.image_original_width ||= 1
      self.image_original_height ||= 1
      self.image_medium_width ||= 1
      self.image_medium_height ||= 1
      self.image_thumb_width ||= 1
      self.image_thumb_height ||= 1
    end
  end

  before_validation :modify_image_file_name
  before_validation :set_default_title

  before_post_process :image?
  after_post_process :save_image_dimensions

  protected

  def modify_image_file_name
    if image.file?
      if image.dirty?
        current_time = Time.now

        basename = "#{current_time.to_i}#{current_time.usec}".ljust(16, '0')

        extension = File.extname(self.image_file_name).downcase

        if extension == '.jpeg'
          extension = '.jpg'
        end

        if extension == '.tif'
          extension = '.tiff'
        end

        self.image.instance_write :file_name, "#{basename}#{extension}"
      end
    end
  end

  def set_default_title
    self.title = File.basename(self.image_file_name, '.*').to_s if self.title.blank? && !self.image_file_name.blank?
  end

  def image?
    self.errors.add :image, 'is not an image'

    !(image_content_type =~ /^image.*/).nil?
  end

  def save_image_dimensions
    original_geometry = Paperclip::Geometry.from_file(image.queued_for_write[:original])
    self.image_original_width = original_geometry.width
    self.image_original_height = original_geometry.height

    medium_geometry = Paperclip::Geometry.from_file(image.queued_for_write[:medium])
    self.image_medium_width = medium_geometry.width
    self.image_medium_height = medium_geometry.height

    thumb_geometry = Paperclip::Geometry.from_file(image.queued_for_write[:thumb])
    self.image_thumb_width = thumb_geometry.width
    self.image_thumb_height = thumb_geometry.height
  end
end
