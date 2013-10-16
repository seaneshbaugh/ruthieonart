class Post < ActiveRecord::Base
  attr_accessible :title, :body, :style, :meta_description, :meta_keywords, :user_id, :visible

  has_paper_trail

  belongs_to :user, :validate => true

  validates_length_of     :title, :maximum => 255
  validates_presence_of   :title
  validates_uniqueness_of :title

  validates_length_of     :slug, :maximum => 255
  validates_presence_of   :slug
  validates_uniqueness_of :slug

  validates_length_of :body, :maximum => 65535

  validates_length_of :style, :maximum => 65535

  validates_length_of :meta_description, :maximum => 65535

  validates_length_of :meta_keywords, :maximum => 65535

  validates_associated  :user
  validates_presence_of :user_id

  after_initialize do
    if self.new_record?
      self.title ||= ''
      self.body ||= ''
      self.style ||= ''
      self.meta_description ||= ''
      self.meta_keywords ||= ''

      if self.visible.nil?
        self.visible = true
      end
    end
  end

  before_validation :generate_slug

  def published?
    visible
  end

  def to_param
    self.slug
  end

  def more
    if self.body.include?('<!--more-->')
      self.body[0..self.body.index('<!--more-->') - 1]
    else
      self.body
    end
  end

  def truncated?
    self.body.length > self.more.length
  end

  def first_image
    images = Nokogiri::HTML(self.body).xpath('//img')

    if images.length > 0
      images[0]['src']
    else
      nil
    end
  end

  protected

  def generate_slug
    if self.title.blank?
      self.slug = self.id.to_s
    else
      self.slug = self.title.gsub(/'/, '').parameterize
    end
  end
end
