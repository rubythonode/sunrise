# encoding: utf-8
module Sunrise
  module Models
    module Header
      extend ActiveSupport::Concern
      
      included do
        belongs_to :headerable, :polymorphic => true
      end
      
      module ClassMethods
      end
      
      def empty?
        [keywords, description, title].map(&:blank?).all?
      end

      def has_info?
        !empty?
      end

      def read(key)
        value = read_attribute(key)
        value.blank? ? nil : value
      end
    end
  end
end