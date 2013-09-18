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
  property :to_contact_id, :class => 'Integer'
  property :to_group_id, :class => 'Integer'
  property :to_organization_id, :class => 'Integer'
  property :shareable_id, :class => 'Integer'
  property :starable_id, :class => 'Integer'
  property :shareable_type, :class => 'String'
  property :owner_module, :class => 'String'
  property :submodule, :class => 'String'
  property :campaign_flag, :class => 'String'
  property :created_at, :class => 'Time'

  def create_notifications(obj)

    case obj.class.to_s
      when 'Share' then
        create_share_notifications (obj)
      when 'Star' then
        create_star_notifications (obj)
      when 'Video' then
        create_video_notifications (obj)
      when 'User' then
        create_user_notifications (obj)
    end
  end

  private
  def create_share_notifications (obj)
    # check if sharing with individual contact
    if obj.contact_id.present?
      if obj.share_contact_type == 'IndividualContact'
        contact = Contact.find(obj.contact_id)
        if contact.related_user_id.present?
          # create notification for the user receiveng the shared item
          notification_index = add_to_user_notifications_list(contact.related_user_id, self.id)
          broadcast "/notifications/user_stream/#{contact.related_user_id}", "{\"index\": \"#{notification_index}\"}"

          # create notification for the user sharing the item
          notification_index = add_to_user_notifications_list(self.user_id, self.id)
          broadcast "/notifications/user_stream/#{self.user_id}", "{\"index\": \"#{notification_index}\"}"
        end
      end

      # check if sharing with contact group
      if obj.share_contact_type == 'ContactGroup'
        group_users_ids = Remodel.redis.lrange "contact_group:#{obj.contact_group_id}:user_ids", 0, -1
        # create notification for each member of the group
        group_users_ids.each do |group_user_id|
          notification_index = add_to_user_notifications_list(group_user_id, self.id)
          broadcast "/notifications/user_stream/#{group_user_id}", "{\"index\": \"#{notification_index}\"}"
        end

        # create notification for the user sharing the item
        notification_index = add_to_user_notifications_list(self.user_id, self.id)
        broadcast "/notifications/user_stream/#{self.user_id}", "{\"index\": \"#{notification_index}\"}"
      end

      # check if sharing with contact organization
      if obj.share_contact_type == "ContactOrganization"
        org_users_ids = Remodel.redis.lrange "contact_organization:#{obj.contact_organization_id}:user_ids", 0, -1
        # create notification for each member of the organization
        org_users_ids.each do |org_user_id|
          notification_index = add_to_user_notifications_list(org_user_id, self.id)
          broadcast "/notifications/user_stream/#{org_user_id}", "{\"index\": \"#{notification_index}\"}"
        end

        # create notification for the user sharing the item
        notification_index = add_to_user_notifications_list(self.user_id, self.id)
        broadcast "/notifications/user_stream/#{self.user_id}", "{\"index\": \"#{notification_index}\"}"
      end
    end
  end

  def create_star_notifications (obj)
    content_owner_users_ids = Remodel.redis.lrange "content_owner:#{obj.starable.content_owner_id}:user_ids", 0, -1
    # create notification for each member of the content owner
    content_owner_users_ids.each do |content_owner_user_id|
      notification_index = add_to_user_notifications_list(content_owner_user_id, self.id)
      broadcast "/notifications/user_stream/#{content_owner_user_id}", "{\"index\": \"#{notification_index}\"}"
    end
  end

  def create_video_notifications (obj)
    content_owner_users_ids = Remodel.redis.lrange "content_owner:#{obj.content_owner_id}:user_ids", 0, -1
    # create notification for each member of the content owner
    content_owner_users_ids.each do |content_owner_user_id|
      notification_index = add_to_user_notifications_list(content_owner_user_id, self.id)
      broadcast "/notifications/user_stream/#{content_owner_user_id}", "{\"index\": \"#{notification_index}\"}"
    end
  end

  def create_user_notifications (obj)
    notification_index = add_to_user_notifications_list(obj.invited_by_id, self.id)
    broadcast "/notifications/user_stream/#{obj.invited_by_id}", "{\"index\": \"#{notification_index}\"}"
  end

  def add_to_user_notifications_list (user_id, impression_id)
    Remodel.redis.lpush "user:#{user_id}:notifications_ids", impression_id
    new_notification_index = (Remodel.redis.rpush "user:#{user_id}:new_notifications_ids", impression_id) - 1

    new_notification_index
  end

  def broadcast (channel, message)
    message = {:channel => channel, :data => message, :ext => {:auth_token => FAYE_TOKEN}}
    uri = URI.parse("http://localhost:9292/faye")
    Net::HTTP.post_form(uri, :message => message.to_json)
  end
end
