require 'rom/factory/builder'

RSpec.describe ROM::Factory::Builder do
  subject(:builder) { ROM::Factory::Builder.new(attributes, relation) }

  include_context 'database'

  let(:factories) do
    ROM::Factory.configure do |config|
      config.rom = rom
    end
  end

  describe 'belongs_to association' do
    let(:attributes) do
      [ROM::Factory::Attributes::Regular.new(:title, 'To-do'),
       ROM::Factory::Attributes::Association.new(tasks.associations[:user], factories.registry[:user])]
    end

    let(:tasks) { relations[:tasks] }
    let(:users) { relations[:users] }
    let(:relation) { tasks }

    before do
      conn.create_table(:users) do
        primary_key :id
        column :name, String
      end

      conn.create_table(:tasks) do
        primary_key :id
        foreign_key :user_id, :users
        column :title, String, null: false
      end

      conf.relation(:tasks) do
        schema(infer: true) do
          associations do
            belongs_to :user
          end
        end
      end

      conf.relation(:users) do
        schema(infer: true)
      end

      factories.define(:user) do |f|
        f.name 'Jane'
      end
    end

    after do
      conn.drop_table(:tasks)
      conn.drop_table(:users)
    end

    describe '#create' do
      it 'builds associated struct' do
        task = builder.create

        expect(task.title).to eql('To-do')
        expect(task.user.name).to eql('Jane')
      end
    end
  end
end
