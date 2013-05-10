
//Representation of one fixed page
ReadiumSDK.Views.OnePageView = Backbone.View.extend({

    spineItem: undefined,
    spine: undefined,

    meta_size : {
        width:undefined,
        height:undefined
    },


    initialize: function() {

        this.spine = this.options.spine;

    },

    isDisplaying:function() {

        return this.spineItem != undefined;
    },

    render: function() {

        var src = this.spineItem ? this.spine.getItemUrl(this.spineItem) : "about:blank";

        ReadiumSDK.Helpers.LoadIframe(this.el, src, this.onIFrameLoad, this);
    },

    remove: function() {

        this.el.src = "about:blank";

        //base remove
        Backbone.View.prototype.remove.call(this);
    },

    onIFrameLoad:  function(success) {

        if(success) {
            this.updateMetaSize();
        }

        this.trigger("PageLoaded");
    },

    updateMetaSize: function() {

        // first try to read viewport size
        var content = $('meta[name=viewport]', this.el.contentDocument).attr("content");

        // if not found try viewbox (used for SVG)
        if(!content) {
            content = $('meta[name=viewbox]', this.el.contentDocument).attr("content");
        }

        if(content) {
            var size = this.parseSize(content);
            if(size) {
                this.meta_size.width = size.width;
                this.meta_size.height = size.height;
            }
        }
        else { //try to get direct image size

            var $img = $(this.el.contentDocument).find('img');
            var width = $img.width();
            var height = $img.height();

            if( width > 0) {
                this.meta_size.width = width;
                this.meta_size.height = height;
            }
        }

    },

    setSpineItem: function(spineItem) {
        this.spineItem = spineItem;
        this.render();
    },

    parseSize: function(content) {

        var pairs = content.replace(/\s/g, '').split(",");

        var dict = {};

        for(var i = 0;  i  < pairs.length; i++) {
            var nameVal = pairs[i].split("=");
            if(nameVal.length == 2) {

                dict[nameVal[0]] = nameVal[1];
            }
        }

        var width = Number.NaN;
        var height = Number.NaN;

        if(dict["width"]) {
            width = parseInt(dict["width"]);
        }

        if(dict["height"]) {
            height = parseInt(dict["height"]);
        }

        if(!isNaN(width) && !isNaN(height)) {
            return { width: width, height: height} ;
        }

        return undefined;
    }

});
