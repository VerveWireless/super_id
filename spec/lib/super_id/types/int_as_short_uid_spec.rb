require 'spec_helper'

module SuperId
  module Types
    describe IntAsShortUid do
      describe IntAsShortUid::DEFAULT_OPTIONS do
        it { expect(subject[:salt]).to eql('') }
        it { expect(subject[:min_hash_length]).to eql(0) }
        it { expect(subject[:alphabet]).to eql(Hashids::DEFAULT_ALPHABET) }
      end
      
      describe '::decode' do
        context 'Mj3' do
          it { expect(IntAsShortUid.decode('Mj3')).to eql(123) }
        end
      end
      
      context 'instantiated with 123' do
        subject { IntAsShortUid.new(123) }
        
        describe '#encode' do
          it { expect(subject.encode).to eql('Mj3') }
        end
      
        describe '#to_s' do
          it { expect(subject.to_s).to eql('Mj3') }
        end
        
        describe '#as_json' do
          it { expect(subject.to_s).to eql('Mj3') }
        end
      
        describe '#to_i' do
          it { expect(subject.to_i).to eql(123) }
        end
      
        describe '#quoted_id' do
          it { expect(subject.quoted_id).to eql('123') }
        end
      
        describe '#==' do
          context 'argument is a SuperId' do
            it { expect(subject == IntAsShortUid.new(123)).to eql(true) }
            it { expect(subject == IntAsShortUid.new(124)).to eql(false) }
          end
        
          context 'argument is an int' do
            it { expect(subject == 123).to eql(true) }
            it { expect(subject == 124).to eql(false) }
          end
        
          context 'argument is a string' do
            it { expect(subject == 'Mj3').to eql(true) }
            it { expect(subject == 'f00').to eql(false) }
          end
        
          context 'argument does not respond to to_i' do
            it { expect(subject == false).to eql(false) }
          end
        end
      end
      
      context 'instantiated with "123"' do
        subject { IntAsShortUid.new('123') }
        
        describe '#to_s' do
          it { expect(subject.to_s).to eql('Mj3') }
        end
        
        describe '#to_i' do
          it { expect(subject.to_i).to eql(123) }
        end
      end
      
      context 'instanatiated with 123 and salt: "foobar"' do
        subject { IntAsShortUid.new(123, salt: 'foobar') }
        
        describe '#to_s' do
          it { expect(subject.to_s).not_to eql('Mj3') }
        end
        
        describe '#to_i' do
          it { expect(subject.to_i).to eql(123) }
        end
      end
      
      context 'instantiated with 123 and min_hash_length: 6' do
        subject { IntAsShortUid.new(123, min_hash_length: 6) }
        
        describe '#to_s' do
          it { expect(subject.to_s.length).to eql(6) }
        end
        
        describe '#to_i' do
          it { expect(subject.to_i).to eql(123) }
        end
      end
      
      context 'instantiated with 123 and alphabet: "0123456789ABCDEF"' do
        let(:alphabet) { "0123456789ABCDEF" }
        subject { IntAsShortUid.new(123, alphabet: alphabet) }
        
        it 'only includes characters from alphabet' do
          subject.to_s.each_char do |char|
            expect(alphabet).to include(char)
          end
        end
      end
    end
  end
end