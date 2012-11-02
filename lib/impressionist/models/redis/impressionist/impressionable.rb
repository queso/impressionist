module Impressionist
  module Impressionable
    include Redis::Objects
    extend ActiveSupport::Concern

    module ClassMethods
      def is_impressionable(options={})
      end
    end

    module InstanceMethods
     def impressions
     end

    end

  end
end
