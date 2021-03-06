# frozen_string_literal: true

module Faraday
  module FlatParamsEncoder
    class << self
      extend Forwardable
      def_delegators :'Faraday::Utils', :escape, :unescape
    end

    def self.encode(params)
      return nil if params.nil?

      unless params.is_a?(Array)
        unless params.respond_to?(:to_hash)
          raise TypeError,
                "Can't convert #{params.class} into Hash."
        end
        params = params.to_hash
        params = params.map do |key, value|
          key = key.to_s if key.is_a?(Symbol)
          [key, value]
        end
        # Useful default for OAuth and caching.
        # Only to be used for non-Array inputs. Arrays should preserve order.
        params.sort!
      end

      # The params have form [['key1', 'value1'], ['key2', 'value2']].
      buffer = +''
      params.each do |key, value|
        encoded_key = escape(key)
        if value.nil?
          buffer << "#{encoded_key}&"
        elsif value.is_a?(Array)
          value.each do |sub_value|
            encoded_value = escape(sub_value)
            buffer << "#{encoded_key}=#{encoded_value}&"
          end
        else
          encoded_value = escape(value)
          buffer << "#{encoded_key}=#{encoded_value}&"
        end
      end
      buffer.chop
    end

    def self.decode(query)
      return nil if query.nil?

      empty_accumulator = {}

      split_query = (query.split('&').map do |pair|
        pair.split('=', 2) if pair && !pair.empty?
      end).compact
      split_query.each_with_object(empty_accumulator.dup) do |pair, accu|
        pair[0] = unescape(pair[0])
        pair[1] = true if pair[1].nil?
        if pair[1].respond_to?(:to_str)
          pair[1] = unescape(pair[1].to_str.tr('+', ' '))
        end
        if accu[pair[0]].is_a?(Array)
          accu[pair[0]] << pair[1]
        elsif accu[pair[0]]
          accu[pair[0]] = [accu[pair[0]], pair[1]]
        else
          accu[pair[0]] = pair[1]
        end
      end
    end
  end
end
