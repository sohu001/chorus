require 'spec_helper'

describe Gpdb::InstanceRegistrar do
  let(:owner) { FactoryGirl.create(:user) }
  let(:valid_instance_attributes) do
    {
        :name => old_name,
        :port => 12345,
        :host => "server.emc.com",
        :maintenance_db => "postgres",
        :provision_type => "register",
        :description => "old description"
    }
  end
  let(:old_name) { "old_name" }

  let(:valid_account_attributes) do
    {
        :db_username => "bob",
        :db_password => "secret"
    }
  end

  let :valid_input_attributes do
    valid_instance_attributes.merge(valid_account_attributes)
  end

  describe ".create!" do
    before do
      stub(Gpdb::ConnectionChecker).check! { true }
    end

    it "requires name" do
      expect {
        Gpdb::InstanceRegistrar.create!(valid_input_attributes.merge(:name => nil), owner)
      }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "requires db connection params" do
      [:maintenance_db].each do |attribute|
        expect {
          Gpdb::InstanceRegistrar.create!(valid_input_attributes.merge(attribute => nil), owner)
        }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    it "requires db username and password" do
      [:db_username, :db_password].each do |attribute|
        expect {
          Gpdb::InstanceRegistrar.create!(valid_input_attributes.merge(attribute => nil), owner)
        }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    it "requires that a real connection to GPDB can be established" do
      stub(Gpdb::ConnectionChecker).check! { raise(ApiValidationError.new) }

      expect { Gpdb::InstanceRegistrar.create!(valid_input_attributes, owner) }.to raise_error
      expect {
        begin
          Gpdb::InstanceRegistrar.create!(valid_input_attributes, owner)
        rescue
        end
      }.not_to change(GpdbInstance, 'count')
    end

    it "caches the db name, owner and connection params" do
      expect {
        Gpdb::InstanceRegistrar.create!(valid_input_attributes, owner)
      }.to change { GpdbInstance.count }.by(1)
      cached_instance = GpdbInstance.find_by_name_and_owner_id(valid_input_attributes[:name], owner.id)
      cached_instance.host.should == valid_input_attributes[:host]
      cached_instance.port.should == valid_input_attributes[:port]
      cached_instance.maintenance_db.should == valid_input_attributes[:maintenance_db]
      cached_instance.provision_type.should == valid_input_attributes[:provision_type]
      cached_instance.description.should == valid_input_attributes[:description]
    end

    it "caches the db username and password" do
      expect {
        Gpdb::InstanceRegistrar.create!(valid_input_attributes, owner)
      }.to change { InstanceAccount.count }.by(1)

      cached_instance = GpdbInstance.find_by_name_and_owner_id(valid_input_attributes[:name], owner.id)
      cached_instance_account = InstanceAccount.find_by_owner_id_and_gpdb_instance_id(owner.id, cached_instance.id)

      cached_instance_account.db_username.should == valid_input_attributes[:db_username]
      cached_instance_account.db_password.should == valid_input_attributes[:db_password]
    end

    it "can save a new instance that is shared" do
      instance = Gpdb::InstanceRegistrar.create!(valid_input_attributes.merge({:shared => true}), owner)
      instance.shared.should == true
    end

    it "sets the instance_provider on the instance" do
      instance = Gpdb::InstanceRegistrar.create!(valid_input_attributes, owner)
      instance[:instance_provider].should == "Greenplum Database"
    end

    it "makes a GreenplumInstanceCreated event" do
      instance = Gpdb::InstanceRegistrar.create!(valid_input_attributes, owner)
      event = Events::GreenplumInstanceCreated.last
      event.gpdb_instance.should == instance
      event.actor.should == owner
    end

    context "creating an aurora instance" do
      before do
        stub(Gpdb::ConnectionChecker).check! { raise "cannot check connection immediately" }
      end

      let(:attributes) do
        {
            :name => "instance_name",
            :description => "Provisioned Instance",
            :db_username => "gpadmin",
            :db_password => "secret"
        }
      end

      it "creates an instance" do
        instance = Gpdb::InstanceRegistrar.create!(attributes, owner, :aurora => true)
        instance.should be_persisted
        instance.name.should == "instance_name"
      end

      it "sets aurora-specific defaults" do
        instance = Gpdb::InstanceRegistrar.create!(attributes, owner, :aurora => true)
        instance.port.should == 5432
        instance.host.should == "provisioning_ip"
        instance.maintenance_db.should == "postgres"
        instance.provision_type.should == "create"
        instance.state.should == "provisioning"
      end
    end
  end

  describe ".update!" do
    before do
      stub(Gpdb::ConnectionChecker).check! { true }
    end

    let(:admin) { FactoryGirl.create(:user, :admin => true) }
    let(:cached_instance) { FactoryGirl.create(:gpdb_instance, valid_instance_attributes.merge(:owner => owner)) }
    let!(:cached_instance_account) { FactoryGirl.create(:instance_account, :db_username => "bob", :owner => owner, :gpdb_instance => cached_instance) }
    let(:updated_attributes) { valid_input_attributes.merge(:name => new_name) }
    let(:new_name) { "new_name" }

    it "allows admin to update" do
      updated_instance = Gpdb::InstanceRegistrar.update!(cached_instance, updated_attributes, admin)
      updated_instance.name.should == new_name
    end

    it "allows instance owners to update" do
      updated_instance = Gpdb::InstanceRegistrar.update!(cached_instance, updated_attributes, owner)
      updated_instance.name.should == new_name
    end

    it "saves the changes to the instance" do
      updated_instance = Gpdb::InstanceRegistrar.update!(cached_instance, updated_attributes, owner)
      updated_instance.reload.name.should == new_name
    end

    it "saves the change of description to the instance" do
      updated_attributes[:description] = "new description"
      updated_instance = Gpdb::InstanceRegistrar.update!(cached_instance, updated_attributes, owner)
      updated_instance.reload.description.should == "new description"
    end

    it "keeps the existing credentials" do
      updated_instance = Gpdb::InstanceRegistrar.update!(cached_instance, updated_attributes, owner)
      owners_account = InstanceAccount.find_by_owner_id_and_gpdb_instance_id(owner.id, updated_instance.id)
      owners_account.db_username.should == "bob"
      owners_account.db_password.should == "secret"
    end

    it "complains if it can't find an existing cached instance" do
      expect {
        Gpdb::InstanceRegistrar.update!(nil, updated_attributes, admin)
      }.to raise_error(Gpdb::InstanceRegistrar::InvalidInstanceError)
    end

    it "requires that a real connection to GPDB can be established" do
      stub(Gpdb::ConnectionChecker).check! { raise(ApiValidationError.new) }
      expect { Gpdb::InstanceRegistrar.update!(cached_instance, updated_attributes, owner) }.to raise_error
      expect {
        begin
          Gpdb::InstanceRegistrar.create!(valid_input_attributes, owner)
        rescue
        end
      }.not_to change { cached_instance.reload.name }
    end

    context "when the name is being changed" do
      it "generates a GreenplumInstanceChangedName event" do
        updated_instance = Gpdb::InstanceRegistrar.update!(cached_instance, updated_attributes, admin)
        event = Events::GreenplumInstanceChangedName.find_last_by_actor_id(admin)
        event.gpdb_instance.should == updated_instance
        event.old_name.should == old_name
        event.new_name.should == new_name
      end
    end

    context "when the name is not being changed" do
      let(:updated_attributes) { valid_input_attributes.merge(:description => "new description") }

      it "does not generate an event" do
        Gpdb::InstanceRegistrar.update!(cached_instance, updated_attributes, admin)
        Events::GreenplumInstanceChangedName.find_last_by_actor_id(admin).should be_nil
      end
    end
  end
end
