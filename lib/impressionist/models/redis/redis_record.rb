class RedisRecord < RedisOrm::Base
  property :ar_id, :class => 'Integer'
  property :ar_class, :class => 'String'
  property :impression_id, :class => 'Integer'

  belongs_to :impression, :relation => :impression
end
