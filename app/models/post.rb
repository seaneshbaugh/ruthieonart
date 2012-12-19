class Post < ActiveRecord::Base
  attr_accessible :title, :body, :style, :visible, :user_id, :user

  has_paper_trail

  belongs_to :user

  validates_presence_of   :title
  validates_uniqueness_of :title

  validates_presence_of   :slug
  validates_uniqueness_of :slug

  before_validation :generate_slug

  def published?
    visible
  end

  def to_param
    self.slug
  end

  protected

  def generate_slug
    if self.title.blank?
      self.slug = self.id.to_s
    else
      self.slug = self.title.parameterize
    end
  end
end
