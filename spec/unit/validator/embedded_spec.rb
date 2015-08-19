describe 'Embedded validators' do
  it 'allows defining a validator for a nested hash' do
    user_validator = Class.new do
      include ROM::Model::Validator

      set_model_name 'User'

      validates :name, presence: true

      embedded :address do
        set_model_name 'Address'

        validates :street, :city, :zipcode, presence: true
      end
    end

    attributes = { name: '', address: { street: '', city: '', zipcode: '' } }

    expect { user_validator.call(attributes) }.to raise_error(
      ROM::Model::ValidationError)

    validator = user_validator.new(attributes)

    expect(validator).to_not be_valid

    expect(validator.errors[:name]).to include("can't be blank")

    address_errors = validator.errors[:address].first

    expect(address_errors).to_not be_empty

    expect(address_errors[:street]).to include("can't be blank")
    expect(address_errors[:city]).to include("can't be blank")
    expect(address_errors[:zipcode]).to include("can't be blank")
  end

  it 'allows defining a validator for a nested array' do
    user_validator = Class.new do
      include ROM::Model::Validator

      set_model_name 'User'

      validates :name, presence: true

      embedded :tasks do
        set_model_name 'Task'

        validates :title, presence: true
      end
    end

    attributes = {
      name: '',
      tasks: [
        { title: '' },
        { title: 'Two' }
      ]
    }

    expect { user_validator.call(attributes) }.to raise_error(
      ROM::Model::ValidationError)

    validator = user_validator.new(attributes)

    expect(validator).to_not be_valid

    expect(validator.errors[:name]).to include("can't be blank")

    task_errors = validator.errors[:tasks]

    expect(task_errors).to_not be_empty

    expect(task_errors[0][:title]).to include("can't be blank")
    expect(task_errors[1]).to be_empty
  end

  it 'validates presence of the nested structure' do
    user_validator = Class.new do
      include ROM::Model::Validator

      set_model_name 'User'

      validates :name, presence: true

      embedded :tasks do
        set_model_name 'Task'

        validates :title, presence: true
      end
    end

    validator = user_validator.new(name: '')
    validator.validate

    expect(validator.errors[:name]).to include("can't be blank")
    expect(validator.errors[:tasks]).to include("can't be blank")
  end

  it 'exposes registered validators in embedded_validators hash' do
    user_validator = Class.new do
      include ROM::Model::Validator

      set_model_name 'User'

      validates :name, presence: true

      embedded :tasks do
        set_model_name 'Task'

        validates :title, presence: true
      end
    end

    expect(user_validator.embedded_validators[:tasks]).to be_present
  end

  it 'adds access to the root node in attribute hash' do
    user_validator = Class.new do
      include ROM::Model::Validator

      set_model_name 'User'

      validates :name, presence: true

      embedded :tasks do
        set_model_name 'Task'

        validate do
          if attributes[:title] != "#{root[:name]} Task"
            errors.add(:base, 'does not look correct')
          end
        end
      end
    end

    attributes = { name: 'Jade', tasks: [{ title: 'Jane Task' }] }

    validator = user_validator.new(attributes)

    validator.validate

    expect(validator.errors[:tasks][0][:base]).to include('does not look correct')
  end

  it 'adds access to the parent node in attribute hash' do
    user_validator = Class.new do
      include ROM::Model::Validator

      set_model_name 'User'

      validates :name, presence: true

      embedded :tasks do
        set_model_name 'Task'

        validate do
          if attributes[:title] != "#{parent[:name]} Task"
            errors.add(:base, 'does not look correct')
          end
        end
      end
    end

    attributes = { name: 'Jade', tasks: [{ title: 'Jane Task' }] }

    validator = user_validator.new(attributes)

    validator.validate

    expect(validator.errors[:tasks][0][:base]).to include('does not look correct')
  end

  it 'allows skipping presence check' do
    user_validator = Class.new do
      include ROM::Model::Validator

      set_model_name 'User'

      validates :name, presence: true

      embedded :tasks, presence: false do
        set_model_name 'Task'
      end
    end

    attributes = { name: 'Jade' }

    validator = user_validator.new(attributes)

    expect(validator).to be_valid
  end

  it 'sets model name' do
    user_validator = Class.new do
      include ROM::Model::Validator

      set_model_name 'User'

      embedded :tasks, presence: false do
        set_model_name 'Task'
      end
    end

    expect(user_validator.embedded_validators[:tasks].model_name.name).to eql('Task')
  end
end
