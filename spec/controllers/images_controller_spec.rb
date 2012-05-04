require "spec_helper"

describe ImagesController do
  before do
    any_instance_of(User) do |user|
      stub(user).save_attached_files { true }
    end
  end

  describe "#update" do
    before do
      @user = FactoryGirl.create(:user, :username => 'some_user', :first_name => "marty")
      log_in @user
    end

    it "updates the user's image" do
      default_image_path = "/images/default-user-icon.png"
      @user.image.url.should == default_image_path
      put :update, :id => @user.id, :files => [Rack::Test::UploadedFile.new(File.expand_path("spec/fixtures/small.png", Rails.root), "image/jpeg")]
      @user.reload
      @user.image.url.should_not == default_image_path
    end

    it "responds with the urls of the new image" do
      put :update, :id => @user.id, :files => [Rack::Test::UploadedFile.new(File.expand_path("spec/fixtures/small.png", Rails.root), "image/jpeg")]
      @user.reload
      decoded_response.original.should == @user.image.url(:original)
      decoded_response.icon.should == @user.image.url(:icon)
    end

    it "generates image jasmine fixtures" do
      put :update, :id => @user.id, :files => [Rack::Test::UploadedFile.new(File.expand_path("spec/fixtures/small.png", Rails.root), "image/jpeg")]
      save_fixture "image.json"
    end
  end
end
