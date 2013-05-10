

//wrapper of the spine object received from hosting application
ReadiumSDK.Models.Spine = Backbone.Model.extend({

    items: [],
    direction: undefined,
    layout: undefined,
    package: undefined,

    initialize : function() {

        this.package = this.get("package");
        var spineData = this.get("spineData");

        if(spineData) {

            this.direction = spineData.direction;
            if(!this.direction) {
                this.direction = "left-to-right";
            }

            this.layout = spineData.layout;

            this.items = spineData.items;

            var length = this.items.length;
            for(var i = 0; i < length; i++) {
                var item = this.items[i];
                item.index = i;
            }
        }

    },

    prevItem:  function(item) {

        if(this.isValidIndex(item.index - 1)) {
            return this.items[item.index - 1];
        }

        return undefined;
    },

    nextItem: function(item){

        if(this.isValidIndex(item.index + 1)) {
            return this.items[item.index + 1];
        }

        return undefined;
    },

    getItemUrl: function(item) {

        return this.package.rootUrl + "/" + item.href;
    },

    isValidIndex: function(index) {

        return index >= 0 && index < this.items.length;
    },

    first: function() {
        return this.items[0];
    },

    last: function() {
        return this.items[this.items.length - 1];
    },

    item: function(index) {
        return this.item(index);
    },

    isRightToLeft: function() {

        return this.direction == "right-to-left";
    },

    isLeftToRight: function() {

        return !this.isRightToLeft();
    },

    getItemById: function(idref) {

        var length = this.items.length;

        for(var i = 0; i < length; i++) {
            if(this.items[i].idref == idref) {

                return this.items[i];
            }
        }

        return undefined;
    },

    getItemByHref: function(href) {

        var length = this.items.length;

        for(var i = 0; i < length; i++) {
            if(this.items[i].href == href) {

                return this.items[i];
            }
        }

        return undefined;
    }

});