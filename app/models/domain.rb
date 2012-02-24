class Domain < ActiveRecord::Base
  THEMES = %w(outline default cyborg slate)
  acts_as_tagger
  has_many :quick_jump_targets, :dependent => :destroy
  has_many :activities, :dependent => :destroy
  has_many :users, :dependent => :destroy
  has_many :favorites

  def tags
    owned_tags.map(&:name).sort
  end

  def tags_for(association_name)
    type = association_name.to_s.singularize.classify
    taggings = owned_taggings.where(:taggable_type => type).includes(:tag).group(:tag_id)
    taggings.map(&:tag).map(&:name).sort
  end
end
