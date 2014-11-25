#!/usr/bin/env ruby

require 'sandstorm/records/redis_record'

require 'flapjack/data/validators/id_validator'

require 'flapjack/data/check'
require 'flapjack/data/rule'

module Flapjack
  module Data
    class Tag

      include Sandstorm::Records::RedisRecord
      include ActiveModel::Serializers::JSON
      self.include_root_in_json = false

      define_attributes :name => :string

      has_and_belongs_to_many :checks,
        :class_name => 'Flapjack::Data::Check', :inverse_of => :tags

      has_and_belongs_to_many :rules,
        :class_name => 'Flapjack::Data::Rule', :inverse_of => :tags

      unique_index_by :name

      # TODO validate uniqueness of name

      validates_with Flapjack::Data::Validators::IdValidator

      def self.jsonapi_attributes
        [:name]
      end

      def self.jsonapi_singular_associations
        []
      end

      def self.jsonapi_multiple_associations
        [:checks, :rules]
      end

      def self.as_jsonapi(options = {})
        tags = options[:resources]
        return [] if tags.nil? || tags.empty?

        unwrap = options[:unwrap]

        tag_ids = options[:ids]
        check_ids = Flapjack::Data::Tag.intersect(:id => tag_ids).
          associated_ids_for(:checks)
        rule_ids = Flapjack::Data::Tag.intersect(:id => tag_ids).
          associated_ids_for(:rules)

        data = tags.collect do |tag|
          tag.as_json(:only => options[:fields]).merge(:links => {
            :checks => check_ids[tag.id],
            :rules  => rule_ids[tag.id]
          })
        end
        return data unless (data.size == 1) && unwrap
        data.first
      end

    end
  end
end
