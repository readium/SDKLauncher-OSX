
ReadiumSDK.Models.SpineItem = function(itemData, index){

    this.idref = itemData.idref;
    this.href = itemData.href;
    this.page_spread = itemData.page_spread;
    this.rendition_layout = itemData.rendition_layout;
    this.index = index;

    this.isLeftPage = function() {

        return !this.isRightPage() && !this.isCenterPage();
    };

    this.isRightPage = function() {
        return this.page_spread === "page-spread-right";
    };

    this.isCenterPage = function() {
        return this.page_spread === "page-spread-center";
    };

    this.isReflowable = function() {

        return !this.isFixedLayout();
    };

    this.isFixedLayout = function() {
        return this.rendition_layout === "pre-paginated";
    }

};