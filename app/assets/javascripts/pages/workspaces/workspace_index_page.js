chorus.pages.WorkspaceIndexPage = chorus.pages.Base.extend({
    crumbs:[
        { label:t("breadcrumbs.home"), url:"#/" },
        { label:t("breadcrumbs.workspaces") }
    ],
    helpId: "workspaces",

    setup:function () {
        this.collection = new chorus.collections.WorkspaceSet();
        this.mainContent = new chorus.views.MainContentList({
                modelClass:"Workspace",
                collection:this.collection,
                linkMenus:{
                    type:{
                        title:t("filter.show"),
                        options:[
                            {data:"active", text:t("filter.active_workspaces")},
                            {data:"all", text:t("filter.all_workspaces")}
                        ],
                        event:"filter"
                    }
                },
                buttons:[
                    {
                        view:"WorkspacesNew",
                        text:t("actions.create_workspace")
                    }
                ]
            }
        );
        this.sidebar = new chorus.views.WorkspaceListSidebar();
        chorus.PageEvents.subscribe("workspace:selected", this.setModel, this);

        this.mainContent.contentHeader.bind("choice:filter", this.choose, this)
        this.choose("active");
    },

    choose:function (choice) {
        this.collection.attributes.active = (choice == "active")
        this.collection.fetch();
    },

    setModel: function(workfile) {
        this.model = workfile;
    }
});