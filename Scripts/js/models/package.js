
ReadiumSDK.Models.Package = Backbone.Model.extend({

    spine: undefined,
    rendition_layout: undefined,
    rootUrl: undefined,


    initialize : function() {

        var packageData = this.get("packageData");

        if(packageData) {

            this.rootUrl = packageData.rootUrl;
            this.rendition_layout = packageData.rendition_layout;
            this.spine = new ReadiumSDK.Models.Spine({spineData: packageData.spine, package: this});

        }

    },


    isFixedLayout: function() {

        return this.rendition_layout === "pre-paginated";
    }


});
