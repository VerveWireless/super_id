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
        super_id_options = options

        define_singleton_method('super_id_names') do
          super_id_names
        end

        define_singleton_method('super_id_type') do
          super_id_type
        end

        define_singleton_method('super_id_options') do
          super_id_options
        end

        # FIXME: should be dynamic based on super_id_type
        define_singleton_method('make_super') do |id, options|
          if id
            SuperId::Types::IntAsShortUid.new(id.to_i, options)
          end
        end

        # FIXME: should be dynamic based on super_id_type
        define_singleton_method('decode_super') do |str, options|
          if str
            SuperId::Types::IntAsShortUid.decode(str, options)
          end
        end

        define_singleton_method('decode_super_ids') do |attributes={}|
          super_id_names.each do |super_id_name|
            if attributes[super_id_name] && attributes[super_id_name].is_a?(String)

              # If attribute being updated is a foreign key (e.g. "template_id"),
              # use the foreign key's class's salt instead of the self's salt
              if self.reflect_on_all_associations.map(&:foreign_key).include?(super_id_name.to_s)
                foreign_key_class = self.reflections.values.detect { |r| r.foreign_key == super_id_name.to_s }.klass
                attributes[super_id_name] = decode_super(attributes[super_id_name], foreign_key_class.super_id_options)
              else
                attributes[super_id_name] = decode_super(attributes[super_id_name], super_id_options)
              end
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

        self.send(:define_method, 'attribute_change') do |attr|
          super(attr).tap do |change|
            change.each_with_index {|val, idx| change[idx] = val.to_i if val.is_a?(SuperId::Types::IntAsShortUid) }
          end
        end

        super_id_names.each do |id_name|
          self.send(:define_method, "#{id_name.to_s}") do |*args|
            id = super(*args)

            foreign_key_class = self.class.reflections.values.detect { |r| r.foreign_key == id_name.to_s }.try(:klass)

            options = if foreign_key_class
              foreign_key_class.super_id_options
            else
              self.class.super_id_options
            end

            self.class.make_super(id.to_i, options) if id
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
