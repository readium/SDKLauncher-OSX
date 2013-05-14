
//used to report pagination state back to the host application
ReadiumSDK.Models.CurrentPagesInfo = function(spineItemCount, isFixedLayout) {

    this.isFixedLayout = isFixedLayout;
    this.spineItemCount = spineItemCount;
    this.openPages = [];

    this.addOpenPage = function(spineItemPageIndex, spineItemPageCount, idref, spineItemIndex) {
        this.openPages.push({spineItemPageIndex: spineItemPageIndex, spineItemPageCount: spineItemPageCount, idref: idref, spineItemIndex: spineItemIndex});

        this.sort();
    };

    this.sort = function() {

        this.openPages.sort(function(a, b) {

            if(a.spineItemIndex != b.spineItemIndex) {
                return a.spineItemIndex - b.spineItemIndex;
            }

            return a.pageIndex - b.pageIndex;

        });

    };

};
