require 'spec_helper'

describe 'Validation' do
  subject(:validator) { user_validator.new(attributes) }

  let(:user_attrs) do
    Class.new {
      include ROM::Model::Attributes

      set_model_name 'User'

      attribute :name, String
      attribute :email, String
    }
  end

  let(:user_validator) do
    Class.new {
      include ROM::Model::Validator

      relation :users

      validates :name, presence: true, uniqueness: { message: 'TAKEN!' }
      validates :email, uniqueness: true

      def self.name
        'User'
      end
    }
  end

  describe '#call' do
    let(:attributes) { user_attrs.new }

    it 'raises validation error when attributes are not valid' do
      expect { validator.call }.to raise_error(ROM::Model::ValidationError)
    end
  end

  describe "#validate" do
    let(:attributes) { user_attrs.new }

    it "sets errors when attributes are not valid" do
      validator.validate
      expect(validator.errors[:name]).to eql(["can't be blank"])
    end
  end

  describe ':presence' do
    let(:attributes) { user_attrs.new(name: '') }

    it 'sets error messages' do
      expect(validator).to_not be_valid
      expect(validator.errors[:name]).to eql(["can't be blank"])
    end
  end

  describe ':uniqueness' do
    let(:attributes) { user_attrs.new(name: 'Jane', email: 'jane@doe.org') }

    it 'sets default error messages' do
      rom.relations.users.insert(name: 'Jane', email: 'jane@doe.org')

      expect(validator).to_not be_valid
      expect(validator.errors[:email]).to eql(['has already been taken'])
    end

    it 'sets custom error messages' do
      rom.relations.users.insert(name: 'Jane', email: 'jane@doe.org')

      expect(validator).to_not be_valid
      expect(validator.errors[:name]).to eql(['TAKEN!'])
    end

    context 'with unique attributes within a scope' do
      let(:attributes) { user_attrs.new(name: 'Jaine', email: 'jane@doe.org') }
      let(:user_validator) do
        Class.new {
          include ROM::Model::Validator

          relation :users

          validates :email, uniqueness: {scope: :name}

          def self.name
            'User'
          end
        }
      end

      it 'does not add errors' do
        rom.relations.users.insert(name: 'Jane', email: 'jane@doe.org')
        expect(validator).to be_valid
      end
    end
  end
end
