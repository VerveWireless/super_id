require 'super_id/types/int_as_short_uid'

module SuperId
  module Models
    module ClassMethods
      def use_super_id_for(id_name_or_names, options={})
        super_id_names = id_name_or_names.respond_to?(:each) ? id_name_or_names : [id_name_or_names]
        super_id_type = options.delete(:as) || :short_uid
        
        # dynamic methods based on super id arguments
        
        class_eval <<-CLASS_METHODS 
          def self.super_id_names
            #{super_id_names}
          end
        
          def self.super_id_type
            #{super_id_type}
          end
        
          def self.super_id_options
            #{options}
          end
        CLASS_METHODS
        
        # dynamic methods based on super id type

        # FIXME: move to a module and set based on super_id_type
        define_method :make_super do |id, options|
          if id
            salt = options[:salt] || ''
            SuperId::Types::IntAsShortUid.new(id.to_i, salt)
          end
        end
        
        # dynamic methods based on super id names
        
        super_id_names.each do |id_name|
          class_eval <<-METHOD
            def #{id_name.to_s}
              id = super
              make_super(id.to_i, self.class.super_id_options) if id
            end
          METHOD
        end
        
        if super_id_names.include? :id or super_id_names.include? 'id'
          class_eval <<-METHOD
            def to_param
              id.to_s
            end
            
            def self.find(id)
              case id
              when String
                # FIXME: Don't assume we're using short_uid's
                super(SuperId::Types::IntAsShortUid.decode(id, super_id_options))
              else
                super(id)
              end
            end
          METHOD
        end
      end
    end
  end
end