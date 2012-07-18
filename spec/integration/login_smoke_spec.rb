require File.join(File.dirname(__FILE__), 'spec_helper')

adminlogin = WEBPATH['admin']['login']
adminpassword = WEBPATH['admin']['password']

describe "logging in" do
  it "logs in" do
    login(adminlogin, adminpassword)
    current_route.should == "/"
  end

  it "logs the user out after two hours" do
    login(adminlogin, adminpassword)
    create_valid_workspace(:name => "FooWorkspace")
    Timecop.travel(Time.current + 3.hours) do
      click_link "Home"
      wait_until { current_route == "/login" }
      login(adminlogin, adminpassword)
      click_link("FooWorkspace")
      Timecop.travel(Time.current + 6.hours) do
        click_link("Home")
        wait_until { current_route == "/login" }
      end
    end

  end
end