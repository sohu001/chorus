chorus.models.HdfsEntry = chorus.models.Base.extend({
    constructorName: "HdfsEntry",
    nameAttribute: 'name',
    entityType: "hdfs_file",

    showUrlTemplate: function() {
        if(this.get("isDir")) {
            return "hadoop_instances/{{hadoopInstance.id}}/browse" + this.getPath() + "/{{encode name}}";
        } else {
            return "hadoop_instances/{{hadoopInstance.id}}/browseFile" + this.getPath() + "/{{encode name}}";
        }
    },

    getPath: function() {
        var encodedPath = encodeURIComponent((this.get("path") == "/") ? "" : this.get("path"));
        return encodedPath.replace(/%2F/g, "/");
    },

    getFullAbsolutePath: function() {
        return this.getPath() + '/' + this.get('name');
    },

    getActivityStreamId: function() {
        var path = (this.get("path") == "/") ? "" : this.get("path")
        return this.getHadoopInstance().id + "|" + path + "/" + this.name();
    },

    pathSegments: function() {
        return _.map(this.get("path").split("/").slice(1), function(path_i, i, whole_path) {
            var cur_path = "/" + whole_path.slice(0, i).join("/")
            return this.clone().set({ name: path_i, path: cur_path, isDir: true })
        }, this)
    },

    parent: function() {
        return _.last(this.pathSegments());
    },

    getHadoopInstance: function() {
        return new chorus.models.HadoopInstance(this.get('hadoopInstance')).set({ instanceProvider: "Hadoop" })
    }
});
