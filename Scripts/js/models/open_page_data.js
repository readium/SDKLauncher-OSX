
ReadiumSDK.Models.OpenPageData = function(spineItem) {

    this.spineItem = spineItem;
    this.pageIndex = undefined;
    this.elementId = undefined;
    this.elementCfi = undefined;

    this.reset = function() {
        this.pageIndex = undefined;
        this.elementId = undefined;
        this.elementCfi = undefined;
    };

    this.setPageIndex = function(pageIndex) {
        this.reset();
        this.pageIndex = pageIndex;
    };

    this.setElementId = function(elementId) {
        this.reset();
        this.elementId = elementId;
    };

    this.setElementCfi = function(elementCfi) {

        this.reset();
        this.elementCfi = elementCfi;
    };
};
