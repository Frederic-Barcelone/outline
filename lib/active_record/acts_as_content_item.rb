module ActsAsContentItem
  extend ActiveSupport::Concern
 
  module ClassMethods
    def acts_as_content_item(options = {})
      Outline::ContentItems.register_class(self)
      if options[:not_postable_directly]
        Outline::ContentItems.not_postable_directly(self)
      end
      instance_eval do
        acts_as_owned_by_user
        
        belongs_to :outer_content, :class_name => "Content", :foreign_key => "content_id", :touch => true
        has_one :content_item, :as => :item, :dependent => :destroy

        after_create do |item|
          content_item = ContentItem.create!(:item => item, :content => item.outer_content)
          content_item.move_to_top
        end
        after_save do |item|
          if item.content_item.content_id != item.content_id
            item.content_item.update_attribute :content_id, item.content_id
          end
        end

        validates_presence_of :outer_content
      end
    end
  end
end

ActiveRecord::Base.send :include, ActsAsContentItem