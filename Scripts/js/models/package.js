
ReadiumSDK.Models.Package = Backbone.Model.extend({

    spine: undefined,
    layout: undefined,
    rootUrl: undefined,


    initialize : function() {

        var packageData = this.get("packageData");

        if(packageData) {

            this.rootUrl = packageData.rootUrl;
            this.layout = packageData.layout;
            this.spine = new ReadiumSDK.Models.Spine({spineData: packageData.spine, package: this});

        }

    },


    isFixedLayout: function() {

        return this.layout == "pre-paginated";
    }


});
