require 'hashids'

module SuperId
  module Types
    class IntAsShortUid
      def initialize(value, salt='')
        @value = value.to_i
        @salt = salt
      end
      
      def self.decode(str, options={})
        salt = options[:salt] || ''
        Hashids.new(salt).decode(str).first
      end
      
      def encode
        Hashids.new(@salt).encode(@value)
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