require 'spec_helper'

module SuperId
  module Models
    describe ClassMethods do
      context 'use super id for primary key' do
        let(:klass) { Flock }
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
      
        describe '::make_super' do
          it { expect(klass.make_super(123)).to be_kind_of(SuperId::Types::IntAsShortUid) }
        end
      
        describe '::decode_super' do
          context 'when value is nil' do
            it { expect(klass.decode_super(nil)).to eql(nil) }
          end
          
          context 'when value is a decodable' do
            it { expect(klass.decode_super('Mj3')).to be_kind_of(SuperId::Types::IntAsShortUid) }
            it { expect(klass.decode_super('Mj3')).to eq(123) }
          end
          
          context 'when value is an arbitrary string' do
            it { expect(klass.decode_super('F00BAR')).to eql(nil) }
          end
        end
      
        describe '::find' do
          subject { klass.create }
          it { expect(klass.find(subject.to_param)).to eql(subject) }
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
        
        describe '::decode_super_ids' do
          it { expect(klass.decode_super_ids({ flock_id: flock.to_param })).to eq({ flock_id: flock.id }) }
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