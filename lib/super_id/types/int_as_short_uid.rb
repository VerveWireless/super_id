require 'hashids'

module SuperId
  module Types
    class IntAsShortUid
      DEFAULT_OPTIONS = {
        salt: '',
        min_hash_length: 0,
        alphabet: Hashids::DEFAULT_ALPHABET
      }

      def initialize(value, options={})
        @value = value.to_i
        @options = DEFAULT_OPTIONS.merge(options)
      end
      
      def self.decode(str, options={})
        options = DEFAULT_OPTIONS.merge(options)
        Hashids.new(options[:salt], options[:min_hash_length], options[:alphabet]).decode(str).first
      end
      
      def encode
        Hashids.new(@options[:salt], @options[:min_hash_length], @options[:alphabet]).encode(@value)
      end
      
      def to_s
        encode
      end
      
      def as_json(options=nil)
        encode
      end
      
      def to_i
        @value
      end
      
      def quoted_id
        @value.to_s
      end
      
      def ==(obj)
        case obj
        when String
          encode == obj
        else
          to_i == obj.to_i
        end
      rescue
        false
      end
    end
  end
end
