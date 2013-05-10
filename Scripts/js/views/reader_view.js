

ReadiumSDK.Views.ReaderView = Backbone.View.extend({

    currentView: undefined,
    package: undefined,
    spine: undefined,

    appFeedback: undefined,

    setPackageData: function(packageData) {

        this.reset();

        this.package = new ReadiumSDK.Models.Package({packageData: packageData});
        this.spine = this.package.spine;

        if(!this.package || ! this.spine) {
            return;
        }

        if(this.package.isFixedLayout()) {

            this.currentView = new ReadiumSDK.Views.FixedView({spine:this.spine});
        }
        else {

            this.currentView = new ReadiumSDK.Views.ReflowableView({spine:this.spine});
        }

        this.appFeedback = new ReadiumSDK.HostAppFeedback(this.currentView);
    },


    openNextPage: function() {
        this.currentView.openNextPage();
    },

    openPrevPage: function() {
        this.currentView.openPrevPage();
    },

    reset: function() {

        if(this.currentView) {

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

        var pageData = new ReadiumSDK.Models.OpenPageData(spineItem);
        if(elementCfi) {
            pageData.setElementCfi(elementCfi);
        }

        this.currentView.openPageData(pageData);
    },

    openSpineItemPage: function(idref, pageIndex) {

        var spineItem = this.getSpineItem(idref);

        if(!spineItem) {
            return;
        }

        var pageData = new ReadiumSDK.Models.OpenPageData(spineItem);
        if(pageIndex) {
            pageData.setPageIndex(pageIndex);
        }

        this.currentView.OpenPageData(pageData);
    },

    // if content ref is relative not ot he package but other file (ex. toc file) we need container ref
    // to resolve contentref relative to the package
    openContentUrl: function(contentRefUrl, sourceFileHref) {

        var combinedPath = this.resolveContentRef(contentRefUrl, sourceFileHref);


        var hashIndex = combinedPath.indexOf("#");
        var hrefPart;
        var elementId;
        if(hashIndex >= 0) {
            hrefPart = combinedPath.splice(0, hashIndex);
            elementId = combinedPath.splice(hashIndex);
        }
        else{
            hrefPart = combinedPath;
            elementId = undefined;
        }

        var spineItem = this.spine.getItemByHref(hrefPart);

        if(!spineItem) {
            return;
        }

        var pageData = new ReadiumSDK.Models.OpenPageData(spineItem)
        pageData.setElementId(elementId);

        this.currentView.openPageData(pageData);
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

        var sourceParts = sourceFileHref.split("/");

        var sourcePartsCount = sourceParts.length;// chop filename

        sourcePartsCount = sourcePartsCount - parentNavCount;

        var leftPart = "";
        if(sourcePartsCount > 0) {
            leftPart = sourceParts.slice(0, sourcePartsCount).join("/");
        }

        var rightPart = pathComponents.splice(parentNavCount);

        var result = leftPart ? leftPart + "/" + rightPart : rightPart;

        return result
    }

});