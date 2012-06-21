require 'spec_helper'

describe ActivityStreamEventMapper do
  let(:mapper) { described_class.new(activity_stream) }

  describe "hadoop instance created event" do
    let(:hadoop_instance) { FactoryGirl.create(:hadoop_instance) }
    let(:activity_stream) do
      Object.new.tap do |activity|
        mock(activity).type { 'INSTANCE_CREATED' }
        mock(activity).instance_hadoop? { true }
      end
    end

    context "#build_event" do
      before do
        mock(activity_stream).rails_hadoop_instance_id { hadoop_instance.id }
      end

      it "builds a valid HADOOP_INSTANCE_CREATED event" do
        event = mapper.build_event
        event.should be_a_kind_of(Events::HADOOP_INSTANCE_CREATED)
      end

      it "sets the hadoop instance target" do
        event = mapper.build_event
        event.hadoop_instance.should == hadoop_instance
      end
    end

    context "#can_build?" do
      it "returns true" do
        mapper.can_build?.should be_true
      end
    end
  end

  describe "greenplum instance created event" do
    let(:greenplum_instance) { FactoryGirl.create(:instance) }
    let(:activity_stream) do
      Object.new.tap do |activity|
        mock(activity).type { 'INSTANCE_CREATED' }
        mock(activity).instance_hadoop? { false }
      end
    end

    context "#build_event" do
      before do
        mock(activity_stream).rails_greenplum_instance_id { greenplum_instance.id }
      end

      it "builds a valid GREENPLUM_INSTANCE_CREATED event" do
        event = mapper.build_event
        event.should be_a_kind_of(Events::GREENPLUM_INSTANCE_CREATED)
      end

      it "sets the greenplum instance target" do
        event = mapper.build_event
        event.greenplum_instance.should == greenplum_instance
      end
    end

    context "#can_build?" do
      it "returns true" do
        mapper.can_build?.should be_true
      end
    end
  end

  describe "workfile created event" do
    let(:workfile) { FactoryGirl.create(:workfile) }
    let(:activity_stream) do
      Object.new.tap do |activity|
        mock(activity).type.twice { 'WORKFILE_CREATED' }
      end
    end

    context "#build_event" do
      before do
        mock(activity_stream).rails_workfile_id { workfile.id }
      end

      it "builds a valid WORKFILE_CREATED event" do
        event = mapper.build_event
        event.should be_a_kind_of(Events::WORKFILE_CREATED)
      end

      it "sets the workfile target" do
        event = mapper.build_event
        event.workfile.should == workfile
      end
    end

    context "#can_build?" do
      it "returns true" do
        mapper.can_build?.should be_true
      end
    end
  end

  describe "instance change owner event" do
    let(:activity_stream) do
      Object.new.tap do |activity|
        mock(activity).type.twice { 'INSTANCE_CHANGED_OWNER' }
      end
    end

    context "#build_event" do
      it "fails to build an event" do
        mapper.build_event.should be_nil
      end
    end

    context "#can_build" do
      it "returns false" do
        mapper.can_build?.should be_false
      end
    end
  end
end