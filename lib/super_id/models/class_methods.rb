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

        define_singleton_method('__foreign_key_map__') do
          @__foreign_key_map__ ||= self.reflect_on_all_associations.inject({}) do |result, reflection|
            result.merge(:"#{reflection.foreign_key}" => reflection.klass)
          end
        end

        # Determines which class the key belongs to (local or foreign),
        # then returns the super_id_options for that class
        define_singleton_method('options_for_keys_class') do |key|
          if (foreign_class = __foreign_key_map__[key])
            foreign_class.super_id_options
          else
            super_id_options
          end
        end

        # Instantiates a IntAsShortUid for the passed in string or id
        # If the value is a string, it is first decoded using the proper salt
        define_singleton_method('create_super_id') do |id, key=nil|
          options = options_for_keys_class(key)
          SuperId::Types::IntAsShortUid.new(decode_id(id, key, options), options)
        end

        define_singleton_method('decode_id') do |value, key=nil, options=nil|
          return value unless value.is_a? String
          options ||= options_for_keys_class(key)

          SuperId::Types::IntAsShortUid.decode(value, options)
        end

        # Scans through argument list and decodes any super_ids with
        # the proper salt of the id's class. Works with either
        # strings or arrays of super_ids.
        define_singleton_method('decode_ids') do |args={}|
          encoded_keys = super_id_names & args.keys

          decoded_hash = encoded_keys.inject({}) do |result, key|
            decode_strategy =
              case args[key]
              when Array
                -> (encoded_array) { encoded_array.map { |encoded_id| decode_id(encoded_id, key) } }
              else
                -> (encoded_id) { decode_id(encoded_id, key) }
              end

            result.merge(key => decode_strategy.(args[key]))
          end

          args.merge(decoded_hash)
        end

        # OVERRIDE class method create(attributes = {}, &block)
        define_singleton_method('create') do |*args|
          args[0] = decode_ids(args[0]) if args[0]
          super(*args)
        end

        # OVERRIDE instance method update(attributes)
        self.send(:define_method, 'update') do |attributes|
          super(self.class.decode_ids(attributes))
        end

        # OVERRIDE instance method assign_attributes(new_attributes)
        self.send(:define_method, 'assign_attributes') do |*args|
          args[0] = self.class.decode_ids(args[0]) if args[0]
          super(*args)
        end

        # OVERRIDE constructor initialize(attributes = nil, options = {})
        self.send(:define_method, 'initialize') do |*args|
          args[0] = self.class.decode_ids(args[0]) if args[0]
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
            self.class.create_super_id(super(*args), id_name) if id
          end
        end

        define_singleton_method('where') do |args|
          super(decode_ids(args))
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
