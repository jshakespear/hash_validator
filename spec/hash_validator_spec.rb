require 'spec_helper'

describe HashValidator do
  describe 'Adding validators' do
    let(:new_validator1) { HashValidator::Validator::SimpleValidator.new('my_type1', lambda { |v| true }) }
    let(:new_validator2) { HashValidator::Validator::SimpleValidator.new('my_type2', lambda { |v| true }) }

    it 'allows validators with unique names' do
      expect {
        HashValidator.append_validator(new_validator1)
      }.to_not raise_error
    end

    it 'does not allow validators with conflicting names' do
      expect {
        HashValidator.append_validator(new_validator2)
        HashValidator.append_validator(new_validator2)
      }.to raise_error(StandardError, 'validators need to have unique names')
    end

    it 'does not allow validators that do not inherit from the base validator class' do
      expect {
        HashValidator.append_validator('Not a validator')
      }.to raise_error(StandardError, 'validators need to inherit from HashValidator::Validator::Base')
    end
  end

  describe '#validate' do
    describe 'individual type validations' do
      it 'should validate hash' do
        validate({ v: {} }, { v: {} }).valid?.should be_true

        validate({ v: '' }, { v: {} }).valid?.should be_false
        validate({ v: '' }, { v: {} }).errors.should eq({ v: 'hash required' })
      end

      it 'should validate presence' do
        validate({ v: 'test' }, { v: 'required' }).valid?.should be_true
        validate({ v: 1234   }, { v: 'required' }).valid?.should be_true

        validate({ v: nil    }, { v: 'required' }).valid?.should be_false
        validate({ v: nil    }, { v: 'required' }).errors.should eq({ v: 'is required' })

        validate({ x: 'test' }, { v: 'required' }).valid?.should be_false
        validate({ x: 'test' }, { v: 'required' }).errors.should eq({ v: 'is required' })

        validate({ x: 1234   }, { v: 'required' }).valid?.should be_false
        validate({ x: 1234   }, { v: 'required' }).errors.should eq({ v: 'is required' })
      end

      it 'should validate string' do
        validate({ v: 'test' }, { v: 'string' }).valid?.should be_true

        validate({ v: 123456 }, { v: 'string' }).valid?.should be_false
        validate({ v: 123456 }, { v: 'string' }).errors.should eq({ v: 'string required' })
      end

      it 'should validate numeric' do
        validate({ v: 1234 }, { v: 'numeric' }).valid?.should be_true
        validate({ v: '12' }, { v: 'numeric' }).valid?.should be_false
      end

      it 'should validate array' do
        validate({ v: [ 1,2,3 ] }, { v: 'array' }).valid?.should be_true
        validate({ v: ' 1,2,3 ' }, { v: 'array' }).valid?.should be_false
      end

      it 'should validate time' do
        validate({ v: Time.now                    }, { v: 'time' }).valid?.should be_true
        validate({ v: '2013-04-12 13:18:05 +0930' }, { v: 'time' }).valid?.should be_false
      end
    end

    describe 'full validations' do
      let(:empty_hash) {{}}

      let(:simple_hash) {{
        foo: 1,
        bar: 'baz'
      }}

      let(:invalid_simple_hash) {{
        foo: 1,
        bar: 2
      }}

      let(:complex_hash) {{
        foo: 1,
        bar: 'baz',
        user: {
          first_name: 'James',
          last_name:  'Brooks',
          age:        27,
          likes:      [ 'Ruby', 'Kendo', 'Board Games' ]
        }
      }}

      let(:invalid_complex_hash) {{
        foo: 1,
        bar: 2,
        user: {
          first_name: 'James',
          last_name:  'Brooks',
          likes:      'Ruby, Kendo, Board Games'
        }
      }}

      describe 'no validations' do
        let(:validations) {{}}

        it 'should validate an empty hash' do
          v = validate(empty_hash, validations)
          v.valid?.should be_true
          v.errors.should be_empty
        end

        it 'should validate a simple hash' do
          v = validate(simple_hash, validations)
          v.valid?.should be_true
          v.errors.should be_empty
        end

        it 'should validate a simple hash 2' do
          v = validate(invalid_simple_hash, validations)
          v.valid?.should be_true
          v.errors.should be_empty
        end

        it 'should validate a complex hash' do
          v = validate(complex_hash, validations)
          v.valid?.should be_true
          v.errors.should be_empty
        end

        it 'should validate a complex hash 2' do
          v = validate(invalid_complex_hash, validations)
          v.valid?.should be_true
          v.errors.should be_empty
        end
      end

      describe 'simple validations' do
        let(:validations) {{ foo: 'numeric', bar: 'string' }}

        it 'should not validate an empty hash (stating missing with required)' do
          v = validate(empty_hash, validations)
          v.valid?.should be_false
          v.errors.should eq({ foo: 'numeric required', bar: 'string required' })
        end

        it 'should validate a simple hash' do
          v = validate(simple_hash, validations)
          v.valid?.should be_true
          v.errors.should be_empty
        end

        it 'should not validate a simple hash 2' do
          v = validate(invalid_simple_hash, validations)
          v.valid?.should be_false
          v.errors.should eq({ bar: 'string required' })
        end

        it 'should validate a complex hash' do
          v = validate(complex_hash, validations)
          v.valid?.should be_true
          v.errors.should be_empty
        end

        it 'should not validate a complex hash 2' do
          v = validate(invalid_complex_hash, validations)
          v.valid?.should be_false
          v.errors.should eq({ bar: 'string required' })
        end
      end

      describe 'nested validations' do
        let(:validations) {{ foo: 'numeric', bar: 'string', user: { first_name: 'string', age: 'required', likes: 'array' } }}

        it 'should validate a complex hash' do
          v = validate(complex_hash, validations)
          v.valid?.should be_true
          v.errors.should be_empty
        end

        it 'should not validate a complex hash 2' do
          v = validate(invalid_complex_hash, validations)
          v.valid?.should be_false
          v.errors.should eq({ bar: 'string required', user: { age: 'is required', likes: 'array required' } })
        end
      end
    end
  end
end
