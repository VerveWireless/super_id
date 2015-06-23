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
        define_singleton_method('make_super') do |id, options={}|
          if id
            SuperId::Types::IntAsShortUid.new(id.to_i, options)
          end
        end

        # FIXME: should be dynamic based on super_id_type
        define_singleton_method('decode_super') do |str, options={}|
          if str
            make_super SuperId::Types::IntAsShortUid.decode(str, options), options
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

        # OVERRIDE class method create(attributes = {}, &block)
        define_singleton_method('create') do |*args|
          args[0] = decode_super_ids(args[0]) if args[0]
          super(*args)
        end

        # OVERRIDE instance method update(attributes)
        self.send(:define_method, 'update') do |attributes|
          super(self.class.decode_super_ids(attributes))
        end

        # OVERRIDE instance method assign_attributes(new_attributes)
        self.send(:define_method, 'assign_attributes') do |*args|
          args[0] = self.class.decode_super_ids(args[0]) if args[0]
          super(*args)
        end

        # OVERRIDE constructor initialize(attributes = nil, options = {})
        self.send(:define_method, 'initialize') do |*args|
          args[0] = self.class.decode_super_ids(args[0]) if args[0]
          super(*args)
        end

        # OVERRIDE instance method attribute_change(attr)
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
