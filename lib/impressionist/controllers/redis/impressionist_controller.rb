ImpressionistController::InstanceMethods.send(:define_method, :impressionist) do |obj, message=nil,opts={}|
  unless bypass
    if obj.respond_to?("impressionable?")
      if unique_instance?(obj, opts[:unique])
        contexts = redis_contexts(obj)

        contexts.each do |context|
            i = Impression.create(Remodel.create_context(context),
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

            broadcast "/notifications/user_stream", "{\"id\": \"#{i.id}\", \"context\": \"#{context}\"}"
        end

      end
    else
      # we could create an impression anyway. for classes, too. why not?
      raise "#{obj.class.to_s} is not impressionable!"
    end
  end
end

def broadcast(channel, message)
  message = {:channel => channel, :data => message, :ext => {:auth_token => FAYE_TOKEN}}
  uri = URI.parse("#{FAYE_URL}/faye")
  Net::HTTP.post_form(uri, :message => message.to_json)
end

def redis_contexts (obj)
  contexts = []

  case obj.class.to_s
    when 'Share' then
      if obj.contact_id.present?
        contact = Contact.find(obj.contact_id)
        user = User.find_by_email(contact.email)
        if !user.nil?
          contexts << "impression_user_#{user.id}"
        end
      elsif obj.group_id.present?
        contexts << "impression_group_#{obj.group_id}"
      elsif obj.organization_id.present?
        contexts << "impression_org_#{obj.organization_id}"
      end
    when 'Star' then
      contexts << "impression_channel_#{obj.starable.channel_id}"
    when 'Video' then
      contexts << "impression_channel_#{obj.channel_id}"
    end

  contexts
end
