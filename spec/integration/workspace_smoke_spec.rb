require File.join(File.dirname(__FILE__), 'spec_helper')

describe "Create workspaces" do
  before(:each) do
    login('edcadmin', 'secret')
  end

  it "creates a private workspace" do
    go_to_workspace_page
    click_button "Create Workspace"
    fill_in 'name', :with => "Private Workspace"
    uncheck ("Make this workspace publicly available")
    create_valid_user(:username => "private")
    login('private','secret')
    go_to_workspace_page
    page.should_not have_content ("Private Workspace")
  end

  it "creates a public workspace" do
    create_valid_workspace
  end
end

describe "deleting a workspace" do
  before(:each) do
    login('edcadmin', 'secret')
  end

  xit "deletes the workspace" do
    workspace_name = "DeleteWorkspace"
    create_valid_workspace(:name => workspace_name)
    click_link "Delete this Workspace"
    wait_until { page.has_selector?(".submit") }
    find(".submit").click

    visit('/#/workspaces')
    wait_until { current_route == '/#/workspaces' }
    page.execute_script("$('.popup').click()")
    click_link("All Workspaces")
    within(".workspace_list") { page.should_not have_content(workspace_name) }
  end
end

