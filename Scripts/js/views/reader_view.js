

ReadiumSDK.Views.ReaderView = Backbone.View.extend({

    currentView: undefined,

    setSpineData: function(spineAsJsonString) {

        this.cleanup();

        var spine = new ReadiumSDK.Models.Spine(JSON.parse(spineAsJsonString));

        if(spine.isFixedLayout()) {

            this.currentView = new ReadiumSDK.Views.FixedView({spine:spine});
        }
        else {

            this.currentView = new ReadiumSDK.Views.ReflowableView({spine:spine});
        }
    },

    cleanup: function() {

        if(this.currentView) {

            this.currentView.remove();
        }
    }

});