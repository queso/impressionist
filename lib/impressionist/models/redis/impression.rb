require 'redis'
require 'redis/objects'
$redis = Redis.new(:host => 'localhost', :port => 6379)
#$redis_context = Remodel.create_context("impression_#{Rails.env}")

class Impression < Remodel::Entity
  #attr_accessible :impressionable_type, :impressionable_id, :user_id,
  #:controller_name, :action_name, :view_name, :request_hash, :ip_address,
  #:session_hash, :message, :referrer, :created_at, :updated_at

  #belongs_to :impressionable, :polymorphic => true

  property :impressionable_type, :class => 'String'
  property :impressionable_id, :class => 'Integer'
  property :user_id, :class => 'Integer'
  property :controller_name, :class => 'String'
  property :action_name, :class => 'String'
  property :view_name, :class => 'String'
  property :request_hash, :class => 'String'
  property :ip_address, :class => 'String'
  property :session_hash, :class => 'String'
  property :message, :class => 'String'
  property :referrer, :class => 'String'
  property :created_at, :class => 'Time'

  #after_save :update_impressions_counter_cache

  private

  #def update_impressions_counter_cache
    #impressionable_class = self.impressionable_type.constantize

    #if impressionable_class.impressionist_counter_cache_options
      #resouce = impressionable_class.find(self.impressionable_id)
      #resouce.try(:update_impressionist_counter_cache)
    #end
  #end
end
