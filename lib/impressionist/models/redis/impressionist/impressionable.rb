module Impressionist
  module Impressionable
    include Redis::Objects
    extend ActiveSupport::Concern

    module ClassMethods
      def is_impressionable(options={})
        #has_many :impressions, :as => :impressionable, :dependent => :destroy
      end
    end

    module InstanceMethods
     def impressions
       #list = []
       #impression_ids.members.each do |id|
         #context = Remodel.create_context("impression_stream_video")
         #list << Impression.find(context, id.to_i)
       #end
       #list
     end

    end

  end
end
