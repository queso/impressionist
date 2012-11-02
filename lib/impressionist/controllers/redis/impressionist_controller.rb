ImpressionistController::InstanceMethods.send(:define_method, :impressionist) do |obj, message=nil,opts={}|
  unless bypass
    if obj.respond_to?("impressionable?")
      if unique_instance?(obj, opts[:unique])
        i = Impression.create($redis_context,
                              :impressionable_type => obj.class.to_s,
                              :impressionable_id => obj.id,
                              :message => message[:message],
                              :controller_name => controller_name,
                              :action_name => action_name,
                              :user_id => user_id,
                              :request_hash => @impressionist_hash,
                              :session_hash => session_hash,
                              :ip_address => request.remote_ip,
                              :referrer => request.referer,
                              :created_at => Time.now)
        obj.impression_ids.add(i.id, Time.now.to_i)
        broadcast_notification(obj, i)
      end
    else
      # we could create an impression anyway. for classes, too. why not?
      raise "#{obj.class.to_s} is not impressionable!"
    end
  end
end

def add_user_notification (user_id, impression_id)
  Remodel.redis.lpush "user:#{user_id}:notifications_ids", impression_id
end

def broadcast (channel, message)
  message = {:channel => channel, :data => message, :ext => {:auth_token => FAYE_TOKEN}}
  uri = URI.parse("#{FAYE_URL}/faye")
  Net::HTTP.post_form(uri, :message => message.to_json)
end

def broadcast_notification (obj, impression)
  case obj.class.to_s
    when 'Share' then
      if obj.individual_contact_id.present?
        contact = IndividualContact.find(obj.individual_contact_id)
        if contact.contact_user_id.present?
          add_user_notification(contact.contact_user_id, impression.id)
          broadcast "/notifications/user_stream/#{contact.contact_user_id}", "{\"impression_id\": \"#{impression.id}\", \"impressionable_id\": \"#{obj.id}\", \"impressionable_class\": \"#{obj.class.to_s}\"}"
        end
      end

      if obj.contact_group_id.present?
        group_users_count = Remodel.redis.llen "contact_group:#{obj.contact_group_id}:user_ids"
        if group_users_count > 0
          group_users_ids = Remodel.redis.lrange "contact_group:#{obj.contact_group_id}:user_ids", 0, group_users_count
          group_users_ids.each do |group_user_id|
            add_user_notification(group_user_id, impression.id)
            broadcast "/notifications/user_stream/#{group_user_id}", "{\"impression_id\": \"#{impression.id}\", \"impressionable_id\": \"#{obj.id}\", \"impressionable_class\": \"#{obj.class.to_s}\"}"
          end
        end
      end

      if obj.contact_organization_id.present?
        org_users_count = Remodel.redis.llen "contact_organization:#{obj.contact_organization_id}:user_ids"
        if org_users_count > 0
          org_users_ids = Remodel.redis.lrange "contact_organization:#{obj.contact_organization_id}:user_ids", 0, org_users_count
          org_users_ids.each do |org_user_id|
            add_user_notification(org_user_id, impression.id)
            broadcast "/notifications/user_stream/#{org_user_id}", "{\"impression_id\": \"#{impression.id}\", \"impressionable_id\": \"#{obj.id}\", \"impressionable_class\": \"#{obj.class.to_s}\"}"
          end
        end
      end
    when 'Star' then
      content_owner_users_count = Remodel.redis.llen "content_owner:#{obj.starable.content_owner_id}:user_ids"
      if content_owner_users_count > 0
        content_owner_users_ids = Remodel.redis.lrange "content_owner:#{obj.starable.content_owner_id}:user_ids", 0, content_owner_users_count
        content_owner_users_ids.each do |content_owner_user_id|
            add_user_notification(content_owner_user_id, impression.id)
            broadcast "/notifications/user_stream/#{content_owner_user_id}", "{\"impression_id\": \"#{impression.id}\", \"impressionable_id\": \"#{obj.id}\", \"impressionable_class\": \"#{obj.class.to_s}\"}"
        end
      end
    when 'Video' then
      content_owner_users_count = Remodel.redis.llen "content_owner:#{obj.content_owner_id}:user_ids"
      if content_owner_users_count > 0
        content_owner_users_ids = Remodel.redis.lrange "content_owner:#{obj.content_owner_id}:user_ids", 0, content_owner_users_count
        content_owner_users_ids.each do |content_owner_user_id|
            add_user_notification(content_owner_user_id, impression.id)
            broadcast "/notifications/user_stream/#{content_owner_user_id}", "{\"impression_id\": \"#{impression.id}\", \"impressionable_id\": \"#{obj.id}\", \"impressionable_class\": \"#{obj.class.to_s}\"}"
        end
      end
    when 'User' then
      add_user_notification(obj.invited_by_id, impression.id)
      broadcast "/notifications/user_stream/#{obj.invited_by_id}", "{\"impression_id\": \"#{impression.id}\", \"impressionable_id\": \"#{obj.id}\", \"impressionable_class\": \"#{obj.class.to_s}\"}"
  end
end
