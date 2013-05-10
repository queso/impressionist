ImpressionistController::InstanceMethods.send(:define_method, :impressionist) do |obj, message=nil,opts={}|
  unless bypass
    if obj.respond_to?("impressionable?")
      if unique_instance?(obj, opts[:unique])
        if defined?(obj.campaign_flag)
          campaign_flag = obj.campaign_flag
        elsif defined?(message[:campaign_flag])
          campaign_flag = message[:campaign_flag]
        else
          campaign_flag = nil
        end
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
                              :to_contact_id => opts[:contact_id],
                              :to_group_id => opts[:group_id],
                              :to_organization_id => opts[:organization_id],
                              :starable_id => obj.class.to_s == 'Star' ? obj.starable_id : nil,
                              :shareable_id => obj.class.to_s == 'Share' ? obj.shareable_id : nil,
                              :shareable_type => obj.class.to_s == 'Share' ? obj.shareable_type : nil,
                              :campaign_flag => campaign_flag,
                              :owner_module => params[:owner_module].present? ? params[:owner_module] : 'nil',
                              :created_at => Time.now)
        obj.impression_ids.add(i.id, Time.now.to_i)
        i.create_notifications(obj)
      end
    else
      # we could create an impression anyway. for classes, too. why not?
      raise "#{obj.class.to_s} is not impressionable!"
    end
  end
end
