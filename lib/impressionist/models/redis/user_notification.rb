require 'redis'
require 'redis/objects'

class UserNotificaion < Remodel::Entity
  property :ar_id, :class => 'Integer'
  property :ar_class, :class => 'String'
  property :impression_id, :class => 'Integer'
end
