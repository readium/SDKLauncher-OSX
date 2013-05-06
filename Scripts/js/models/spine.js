

//wrapper of the spine object received from hosting application
ReadiumSDK.Models.Spine = Backbone.Model.extend({

    items: undefined,
    direction: undefined,
    layout: undefined,

    initialize : function() {

        var spineData = this.get("spine");

        if(spineData) {

            this.direction = spineData.direction;
            if(!this.direction) {
                this.direction = "left-to-right";
            }

            this.layout = spineData.layout;

            this.items = spineData.items;

            for(var i = 0; i < this.items.length; i++) {
                var item = this.items[i];
                item.index = i;
            }
        }

    },

    isFixedLayout: function() {

        return this.layout == "pre-paginated";
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
    }

});