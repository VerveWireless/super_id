require 'super_id/types/int_as_short_uid'

module SuperId
  module Models
    module ClassMethods
      # Examples
      #   Use Super ID for the primary key
      #     use_super_id_for :id
      #   Use Super ID for primary and foreign keys
      #     use_super_id_for [:id, :other_id]
      #   Use specific algorithm (with options)
      #     use_super_id_for :id, as: :short_uid, salt: 'MySalt'
      def use_super_id_for(id_name_or_names, options={})
        super_id_names = id_name_or_names.respond_to?(:each) ? id_name_or_names : [id_name_or_names]
        super_id_type = options.delete(:as) || :short_uid
        
        class_eval <<-METHODS
          def self.super_id_names
            #{super_id_names}
          end
        
          def self.super_id_type
            #{super_id_type}
          end
        
          def self.super_id_options
            #{options}
          end
          
          # FIXME: should be dynamic based on super_id_type
          def self.make_super(id, options)
            if id
              salt = options[:salt] || ''
              SuperId::Types::IntAsShortUid.new(id.to_i, salt)
            end
          end
          
          # FIXME: should be dynamic based on super_id_type
          def self.decode_super(str, options)
            if str
              SuperId::Types::IntAsShortUid.decode(str, options)
            end
          end
          
          def self.decode_super_ids(attributes={})
            super_id_names.each do |super_id_name|
              if attributes[super_id_name]
                # FIXME: if the column is a foreign key, then use the super_id_options from the other class
                #        otherwise, all the options has to be the same (ex: salt)
                attributes[super_id_name] = decode_super(attributes[super_id_name], super_id_options)
              end
            end
            attributes
          end
          
          def self.create(attributes={}, options={}, &block)
            super(decode_super_ids(attributes), options, &block)
          end
          
          def initialize(attributes={}, options={})
            super(self.class.decode_super_ids(attributes), options)
          end
          
          def update(attributes)
            super(self.class.decode_super_ids(attributes))
          end
        METHODS
        
        super_id_names.each do |id_name|
          class_eval <<-METHODS
            def #{id_name.to_s}
              id = super
              self.class.make_super(id.to_i, self.class.super_id_options) if id
            end
          METHODS
        end
        
        if super_id_names.include? :id or super_id_names.include? 'id'
          class_eval <<-METHODS
            def self.find(id)
              case id
              when String
                # FIXME: Don't assume we're using short_uid's
                super(SuperId::Types::IntAsShortUid.decode(id, super_id_options))
              else
                super(id)
              end
            end
            
            def to_param
              id.to_s
            end
          METHODS
        end
      end
    end
  end
end