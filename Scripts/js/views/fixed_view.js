
ReadiumSDK.Views.FixedView = Backbone.View.extend({

    el: "body",

    leftPageView: undefined,
    rightPageView: undefined,
    centerPageView: undefined,

    spread: undefined,

    initialize: function() {

        template: _.template($("#template-fixed-view").html());
        var html = this.template({});
        this.$el.append(html);

        this.spread = new ReadiumSDK.Models.Spread(this.options.spine);

        this.leftPageView = new ReadiumSDK.Views.OnePageView({el: document.getElementById("fixed_left_iframe")});
        this.rightPageView = new ReadiumSDK.Views.OnePageView({el: document.getElementById("fixed_right_iframe")});
        this.centerPageView = new ReadiumSDK.Views.OnePageView({el: document.getElementById("fixed_center_iframe")});

        this.spread.openFirst();

        //event with namespace for clean unbinding
        $(window).on("resize.ReadiumSDK.readerView", _.bind(this.onViewportResize, this));
    },

    remove: function() {

        $(window).off("resize.ReadiumSDK.readerView");

        //base remove
        Backbone.View.prototype.remove.call(this);
    },

    onViewportResize: function() {

        this.fitToScreen();
    },

    fitToScreen: function() {

        var bookSize = this.getBookViewSize();
        if(bookSize.width == 0) {
            return;
        }

        var containerWidth = this.$el.width();
        var containerHeight = this.$el.height();

        var horScale = containerWidth / bookSize.width;
        var verScale = containerHeight / bookSize.height;

        var scale = Math.min(horScale, verScale);

        var newWidth = bookSize.width * scale;
        var newHeight = bookSize.height * scale;

        var left = Math.floor((containerWidth - newWidth) / 2);
        var top = Math.floor((containerHeight - newHeight) / 2);

        var css = this.generateTransformCSS(left, top, scale);
        css["width"] = bookSize.width;
        css["height"] = bookSize.height;

        this.$("#page-wrap").css(css);
    },

    generateTransformCSS: function(left, top, scale) {

        var transformString = "translate(" + left + "px, " + top + "px) scale(" + scale + ")";

        //modernizer library can be used to get browser independent transform attributes names (implemented in readium-web fixed_layout_book_zoomer.js)
        var css = {};
        css["-webkit-transform"] = transformString;
        css["-webkit-transform-origin"] = "0 0";

        return css;
    },

    getBookViewSize: function() {

        var size = {width: 0, height: 0};

        if( this.centerPageView.isDisplaying() ) {
            size.width = this.centerPageView.meta_size.width;
            size.height = this.centerPageView.meta_size.height;
        }
        else if( this.leftPageView.isDisplaying() && this.rightPageView.isDisplaying() ) {
            size.width = Math.max(this.leftPageView.meta_size.width, this.rightPageView.meta_size.width) * 2;
            size.height = Math.max(this.leftPageView.meta_size.height, this.rightPageView.meta_size.height);
        }
        else if( this.leftPageView.isDisplaying() ) {
            size.width = this.leftPageView.meta_size.width * 2;
            size.height = this.leftPageView.meta_size.height;
        }
        else if( this.rightPageView.isDisplaying() ) {
            size.width = this.rightPageView.meta_size.width * 2;
            size.height = this.rightPageView.meta_size.height;
        }

        return size;
    },

    render: function(){


        var self = this;

        $.when( this.setPageViewItem(this.leftPageView, this.spread.leftItem),
                this.setPageViewItem(this.rightPageView, this.spread.rightItem),
                this.setPageViewItem(this.centerPageView, this.spread.centerItem)  ).done(function(){ self.fitToScreen() });

    },

    openLeft: function() {

        this.spread.openLeft();
        this.render();
    },

    openRight: function() {

        this.spread.openRight();
        this.render();
    },

    setPageViewItem: function(pageView, item) {

        var dfd = $.Deferred();

        pageView.on("PageLoaded", dfd.resolve);

        pageView.setSpineItem(item);

        return dfd.promise();

    }

});