/**
 * This object is not instantiated directly but provided by the host application to the DOMAccess layer in the
 * ReadiumSDK.Views.ReaderView.openBook function
 *
 * Provided for reference only
 *
 * @type {{rootUrl: string, rendering_layout: string, spine: {direction: string, items: Array}}}
 */

ReadiumSDK.Models.PackageData = {

    /** {string} Url of the package file*/
    rootUrl: "",
    /** {string} "reflowable"|"pre-paginated" */
    rendering_layout: "",

    spine: {

        direction: "ltr",
        items: [
            {
                href:"",
                idref:"",
                page_spread:"", //"page-spread-left"|"page-spread-right"|"page-spread-center"
                rendering_layout:"" //"reflowable"|"pre-paginated"
            }
        ]
    }
};
