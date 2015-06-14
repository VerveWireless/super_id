require 'super_id/models/class_methods'

module SuperId
  if defined?(Rails::Railtie)
    class Railtie < Rails::Railtie
      initializer 'use_super_id_for.insert_into_active_record' do
        ActiveSupport.on_load :active_record do
          ActiveRecord::Base.send(:extend, SuperId::Models::ClassMethods)
        end
      end
    end
  end
end