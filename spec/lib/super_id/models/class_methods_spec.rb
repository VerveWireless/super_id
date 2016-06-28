require 'spec_helper'

module SuperId
  module Models
    describe ClassMethods do
      context 'use super id for primary key' do
        let(:klass) { Flock }
        let(:salted_klass) do
          Class.new(ActiveRecord::Base) do
            use_super_id_for(:id, { salt: 'salty' })
            self.table_name = Flock.table_name
          end
        end

        subject { klass.new }
        
        describe '::super_id_names' do
          it { expect(klass.super_id_names).to eql([:id]) }
        end
      
        describe '::super_id_type' do
          it { expect(klass.super_id_type).to eql(:short_uid) }
        end
      
        describe '::super_id_options' do
          it { expect(klass.super_id_options).to eql({}) }
        end
      
        describe '::create_super_id' do
          it { expect(klass.create_super_id('Mj3')).to be_kind_of(SuperId::Types::IntAsShortUid) }
          it { expect(klass.create_super_id('Mj3').to_i).to eq(123) }
          it { expect(klass.create_super_id(123).to_s).to eq('Mj3') }
          it { expect(klass.create_super_id(nil)).to eq(nil) }
          it { expect(klass.create_super_id(nil)).to eq(nil) }

          context 'when salt' do
            it { expect(salted_klass.decode_id('0zJ')).to eq(123) }
          end

          context 'when foreign salt' do
            let(:fake_foreign_hash) { { foreign_id: salted_klass } }
            before { allow(klass).to receive(:__foreign_key_map__).and_return(fake_foreign_hash) }

            it { expect(klass.decode_id('0zJ', :foreign_id)).to eq(123) }
          end
        end
      
        describe '::decode_id' do
          context 'when value is nil' do
            it { expect(klass.decode_id(nil)).to eql(nil) }
          end
          
          context 'when value is a decodable' do
            it { expect(klass.decode_id('Mj3')).to eq(123) }
          end
          
          context 'when value is an arbitrary string' do
            it { expect(klass.decode_id('F00BAR')).to eql(nil) }
          end

          context 'when class has a salt' do
            it { expect(salted_klass.decode_id('0zJ')).to eq(123) }
          end

          context 'when value is a foreign key with a different salt' do
            let(:fake_foreign_hash) { { foreign_id: salted_klass } }
            before { allow(klass).to receive(:__foreign_key_map__).and_return(fake_foreign_hash) }

            it { expect(klass.decode_id('0zJ', :foreign_id)).to eq(123) }
          end
        end
      
        describe '::find' do
          subject { klass.create }

          context 'without salt' do
            it { expect(klass.find(subject.to_param)).to eql(subject) }
          end

          context 'with salt' do
            subject { salted_klass.create }
            it { expect(salted_klass.find(subject.to_param)).to eql(subject) }
          end
        end

        describe '::where' do
          subject { klass.create() }

          context 'when no super_id value' do
            it { expect(klass.where(id: subject.id.to_i).to_a).to eql([subject]) }
          end

          context 'when single super_id value' do
            it { expect(klass.where(id: subject.to_param).to_a).to eql([subject]) }
          end

          context 'when single, salted super_id value' do
            subject { salted_klass.create }
            it { expect(salted_klass.where(id: subject.to_param).to_a).to eql([subject]) }
          end

          context 'when multiple super_id values' do
            subject { 2.times.map { klass.create() } }
            it { expect(klass.where(id: [subject.first.to_param, subject.last.to_param]).to_a).to eql(subject) }
          end

          context 'when super_id value plus additional conditions' do
            it { expect(klass.where(id: subject.to_param, created_at: subject.created_at).to_a).to eql([subject]) }
          end

          context 'when column is salted foreign key' do
            let(:flock) { salted_klass.create }
            subject { Seagull.create(flock_id: flock.id) }

            it 'uses foreign key\'s salt to decode super_ids' do
              subject
              expect(Seagull.where(flock_id: flock.id.to_i).to_a).to eql([subject])
            end
          end

          context 'when called with SQL' do
            let(:flock) { salted_klass.create }
            subject { Seagull.create(flock_id: flock.id) }

            context 'when no super_id value' do
              it { expect(Seagull.where('id = ? AND flock_id = ?', subject.id.to_i, flock.id.to_i).to_a).to eql([subject]) }
            end

            context 'when super_id value' do
              it { expect(Seagull.where('id = ?', subject.id.to_param).to_a).to eql([subject]) }
            end

            context 'when super_id is salted foreign key' do
              before { allow(Flock).to receive(:super_id_options).and_return(salted_klass.super_id_options) }
              it { expect(Seagull.where('id = ? AND flock_id = ?', subject.id.to_param, flock.id.to_param).to_a).to eql([subject]) }
            end

            context 'when no variables' do
              it { expect(Seagull.where("id = #{subject.id.to_i}").to_a).to eql([subject]) }
            end
          end
        end
      
        describe '#id' do
          context 'when not persisted' do
            subject { klass.new }
            it { expect(subject.id).to be_nil }
          end
          
          context 'when persisted' do
            subject { klass.create }
            it { expect(subject.id).to be_kind_of(SuperId::Types::IntAsShortUid) }
          end
        end
      
        describe '#to_param' do
          before { allow(subject).to receive(:id).and_return(SuperId::Types::IntAsShortUid.new(123)) }
          it { expect(subject.to_param).to eql('Mj3') }
        end
      end
      
      context 'use super id for primary and foreign key' do
        let(:klass) { Seagull }
        let(:flock) { Flock.create }
        subject { klass.new flock: flock }
        
        describe '::new' do
          let(:seagull) { Seagull.new flock_id: flock.to_param }
          it { expect(seagull.flock).to eql(flock) }
        end
        
        describe '::decode_ids' do
          it { expect(klass.decode_ids({ flock_id: flock.to_param })).to eq({ flock_id: flock.id }) }
        end
      
        describe '::create' do
          let(:seagull) { Seagull.create flock_id: flock.to_param }
          it { expect(seagull.reload.flock).to eql(flock) }
        end
        
        describe '#update' do
          let(:seagull) { Seagull.create flock_id: flock.to_param }
          
          it 'updates the model' do
            new_flock = Flock.create
            seagull.update({ flock_id: new_flock.to_param })
            seagull.reload
            expect(seagull.flock).to eql(new_flock)
          end
        end
        
        describe '#assign_attributes' do
          let(:seagull) { Seagull.create flock_id: flock.to_param }
          
          it 'assigns attributes to the model' do
            new_flock = Flock.create
            seagull.assign_attributes({ flock_id: new_flock.to_param })
            seagull.save
            seagull.reload
            expect(seagull.flock).to eql(new_flock)
          end
        end
      
        describe '#attribute_change' do
          let(:seagull) { Seagull.create flock_id: flock.to_param }
          
          it 'returns the change' do
            new_flock = Flock.create
            seagull.flock_id = new_flock.id
            expect(seagull.attribute_change(:flock_id)).to eql([flock.id.to_i, new_flock.id.to_i])
          end
          
          it 'returns no change' do
            seagull.flock_id = flock.id
            expect(seagull.attribute_change(:flock_id)).to eql([flock.id.to_i, flock.id.to_i])
          end
        end
        
        describe '#id' do
          subject { klass.create flock: flock }
          it { expect(subject.id).to be_kind_of(SuperId::Types::IntAsShortUid) }
        end
        
        describe '#flock_id' do
          subject { klass.create flock: flock }
          it { expect(subject.flock_id).to be_kind_of(SuperId::Types::IntAsShortUid) }
        end
        
        describe '#to_param' do
          before { allow(subject).to receive(:id).and_return(SuperId::Types::IntAsShortUid.new(123)) }
          it { expect(subject.to_param).to eql('Mj3') }
        end
      end
    end
  end
end
