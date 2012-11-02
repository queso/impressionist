require 'redis'
require 'redis/objects'

class Impression < Remodel::Entity
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
end
