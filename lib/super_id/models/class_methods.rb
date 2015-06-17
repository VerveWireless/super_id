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

        define_singleton_method('super_id_names') do
          super_id_names
        end

        define_singleton_method('super_id_type') do
          super_id_type
        end

        define_singleton_method('super_id_options') do
          options
        end

        # FIXME: should be dynamic based on super_id_type
        define_singleton_method('make_super') do |id, options|
          if id
            salt = options[:salt] || ''
            SuperId::Types::IntAsShortUid.new(id.to_i, salt)
          end
        end
        #
        # FIXME: should be dynamic based on super_id_type
        define_singleton_method('decode_super') do |str, options|
          if str
            SuperId::Types::IntAsShortUid.decode(str, options)
          end
        end

        define_singleton_method('decode_super_ids') do |attributes={}|
          super_id_names.each do |super_id_name|
            if attributes[super_id_name] && attributes[super_id_name].is_a?(String)
              # FIXME: if the column is a foreign key, then use the super_id_options from the other class
              #        otherwise, all the options has to be the same (ex: salt)
              attributes[super_id_name] = decode_super(attributes[super_id_name], super_id_options)
            end
          end
          attributes
        end

        define_singleton_method('create') do |attributes={}, options={}, &block|
          super(decode_super_ids(attributes), options, &block)
        end

        self.send(:define_method, 'update') do |attributes|
          super(self.class.decode_super_ids(attributes))
        end

        self.send(:define_method, 'assign_attributes') do |new_attributes|
          super(self.class.decode_super_ids(new_attributes))
        end

        self.send(:define_method, 'initialize') do |attributes={}, *options|
          super(self.class.decode_super_ids(attributes), options)
        end

        super_id_names.each do |id_name|
          self.send(:define_method, "#{id_name.to_s}") do |*args|
            id = super(*args)
            self.class.make_super(id.to_i, self.class.super_id_options) if id
          end
        end

        if super_id_names.include? :id or super_id_names.include? 'id'
            define_singleton_method('find') do |id|
              case id
              when String
                # FIXME: Don't assume we're using short_uid's
                super(SuperId::Types::IntAsShortUid.decode(id, super_id_options))
              else
                super(id)
              end
            end

            self.send(:define_method, 'to_param') do
              id.to_s
            end
        end
      end
    end
  end
end
