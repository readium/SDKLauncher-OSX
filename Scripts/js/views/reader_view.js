

ReadiumSDK.Views.ReaderView = Backbone.View.extend({

    el: 'body',
    currentView: undefined,
    package: undefined,
    spine: undefined,

    render: function() {

        if(!this.package || ! this.spine) {
            return;
        }

        if(this.package.isFixedLayout()) {

            this.currentView = new ReadiumSDK.Views.FixedView({spine:this.spine});
        }
        else {

            this.currentView = new ReadiumSDK.Views.ReflowableView({spine:this.spine});
        }

        this.$el.append(this.currentView.render().$el);

        var self = this;
        this.currentView.on("PageChanged", function(){

            var paginationReportData = self.currentView.getPaginationInfo();
            ReadiumSDK.HostAppFeedback.ReportPageChanged(paginationReportData);

        });

    },

    //API
    openBook: function(packageData, openPageRequestData) {

        this.reset();

        this.package = new ReadiumSDK.Models.Package({packageData: packageData});
        this.spine = this.package.spine;

        this.render();

        if(openPageRequestData) {

            if(openPageRequestData.idref) {

                if(openPageRequestData.pageIndex) {
                    this.openSpineItemPage(openPageRequestData.idref, openPageRequestData.pageIndex);
                }
                else if(openPageRequestData.elementCfi) {
                    this.openSpineItemElementCfi(openPageRequestData.idref, openPageRequestData.elementCfi);
                }
                else {
                    this.openSpineItemPage(openPageRequestData.idref, 0);
                }
            }
            else {
                console.log("Invalid page request data: idref required!");

            }
        }
        else {// if we where not asked to open specific page we will open the first one

            var spineItem = this.spine.first();
            if(spineItem) {
                var pageOpenRequest = new ReadiumSDK.Models.PageOpenRequest(spineItem);
                pageOpenRequest.setFirstPage();
                this.currentView.openPage(pageOpenRequest);
            }

        }

    },

    //API
    openPageLeft: function() {

        if(this.package.spine.isLeftToRight()) {
            this.openPagePrev();
        }
        else {
            this.openPageNext();
        }
    },

    //API
    openPageRight: function() {

        if(this.package.spine.isLeftToRight()) {
            this.openPageNext();
        }
        else {
            this.openPagePrev();
        }

    },

    //API
    openPageNext: function() {
        this.currentView.openPageNext();
    },

    //API
    openPagePrev: function() {
        this.currentView.openPagePrev();
    },

    reset: function() {

        if(this.currentView) {

            this.currentView.off("PageChanged");
            this.currentView.remove();
        }
    },

    getSpineItem: function(idref) {

        if(!idref) {

            console.log("idref parameter value missing!");
            return undefined;
        }

        var spineItem = this.spine.getItemById(idref);
        if(!spineItem) {
            console.log("Spine item with id " + idref + " not found!");
            return undefined;
        }

        return spineItem;

    },

    openSpineItemElementCfi: function(idref, elementCfi) {

        var spineItem = this.getSpineItem(idref);

        if(!spineItem) {
            return;
        }

        var pageData = new ReadiumSDK.Models.PageOpenRequest(spineItem);
        if(elementCfi) {
            pageData.setElementCfi(elementCfi);
        }

        this.currentView.openPage(pageData);
    },

    //API
    openPage: function(pageIndex) {

        if(!this.currentView) {
            return;
        }

        var pageRequest;
        if(this.package.isFixedLayout()) {
            var spineItem = this.package.spine.items[pageIndex];
            if(!spineItem) {
                return;
            }

            pageRequest = new ReadiumSDK.Models.PageOpenRequest(spineItem);
            pageRequest.setPageIndex(0);
        }
        else {

            pageRequest = new ReadiumSDK.Models.PageOpenRequest(undefined);
            pageRequest.setPageIndex(pageIndex);

        }

        this.currentView.openPage(pageRequest);
    },

    //API
    openSpineItemPage: function(idref, pageIndex) {

        var spineItem = this.getSpineItem(idref);

        if(!spineItem) {
            return;
        }

        var pageData = new ReadiumSDK.Models.PageOpenRequest(spineItem);
        if(pageIndex) {
            pageData.setPageIndex(pageIndex);
        }

        this.currentView.openPage(pageData);
    },

    // if content ref is relative not ot he package but other file (ex. toc file) we need container ref
    // to resolve contentref relative to the package
    //API
    openContentUrl: function(contentRefUrl, sourceFileHref) {

        var combinedPath = this.resolveContentRef(contentRefUrl, sourceFileHref);


        var hashIndex = combinedPath.indexOf("#");
        var hrefPart;
        var elementId;
        if(hashIndex >= 0) {
            hrefPart = combinedPath.splice(0, hashIndex);
            elementId = combinedPath.splice(hashIndex);
        }
        else {
            hrefPart = combinedPath;
            elementId = undefined;
        }

        var spineItem = this.spine.getItemByHref(hrefPart);

        if(!spineItem) {
            return;
        }

        var pageData = new ReadiumSDK.Models.PageOpenRequest(spineItem)
        pageData.setElementId(elementId);

        this.currentView.openPage(pageData);
    },

    resolveContentRef: function(contentRef, sourceFileHref) {

        if(!sourceFileHref) {
            return contentRef;
        }

        var sourceParts = sourceFileHref.split("/");
        var pathComponents = contentRef.split("/");

        var parentNavCount = 0;
        for(var part in pathComponents) {

            if(!(part === "..") || parentNavCount >= sourceParts.length) {
                break;
            }

            parentNavCount++;
        }


        var sourcePartsCount = sourceParts.length;// chop filename

        sourcePartsCount = sourcePartsCount - parentNavCount;

        var leftPart = "";
        if(sourcePartsCount > 0) {
            leftPart = sourceParts.slice(0, sourcePartsCount).join("/");
        }

        var rightPart = pathComponents.splice(parentNavCount);

        return leftPart ? leftPart + "/" + rightPart : rightPart
    },

    //API
    getFirstVisibleElementCfi: function() {

        return this.currentView.getFirstVisibleElementCfi();

    }

});