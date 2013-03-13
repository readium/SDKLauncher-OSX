//  LauncherOSX
//
//  Created by Boris Schneiderman.
//  Copyright (c) 2012-2013 The Readium Foundation.
//
//  The Readium SDK is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.

ReadiumSDK.Views.CfiNavigationLogic = Backbone.View.extend({

    el: '#epubContentIframe',

    initialize: function () {

        this.$viewport = $("#viewport");

    },

    getRootElement: function(){

        return this.$el[0].contentDocument.documentElement

    },

//    getVisibleElements: function(){
//
//        var list = [];
//
//        var viewPortOffset = this.$viewport.offset();
//
//        var viewportRect = {
//            left: viewPortOffset.left,
//            top: viewPortOffset.top,
//            width: this.$viewport.width(),
//            height: this.$viewport.height()
//        };
//
//        var body = $("body", this.getRootElement())[0];
//
//        this.getVisibleChildren(body, viewportRect, list);
//
//        return list;
//    },
//
//    getVisibleChildren: function(element, viewportRect, visibleChildren) {
//
//        var elementOffset = $(element).offset();
//        var elementBottom = elementOffset.top + $(element).height();
//
//        //we passed viewport
//        if(elementOffset.left > viewportRect.left + viewportRect.width) {
//            return false;
//        }
//
//        //is visible in viewport
//        if(elementOffset.left >= viewportRect.left
//            && elementOffset.top < viewportRect.top + viewportRect.width
//            && elementBottom > viewportRect.top  ) {
//
//            if(!element.children) {
//                var n = 9;
//            }
//
//            //has children
//            if(element.children && element.children.length > 0) {
//
//                for(var i = 0; i < element.children.length; i++) {
//                    if( !this.getVisibleChildren(element.children[i], viewportRect, visibleChildren)) {
//                        return false;
//                    }
//                }
//            }
//            else {
//
//                visibleChildren.push(element);
//            }
//
//        }
//
//        //continue iteration
//        return true;
//    },
//
//    findVisibleTextNode: function() {
//
//        var visibleElements = this.getVisibleElements();
//
//        var textElem = undefined;
//
//        $(visibleElements).contents().each(function(){
//
//            if(this.nodeType === 3) {
//
//                textElem = this;
//                return false;
//            }
//
//        });
//
////        return $(textElem).parent();
//        return $(textElem);
//
//    },

    // TODO: Extend this to be correct for right-to-left pagination
    findVisibleTextNode: function () {

        var $elements;
        var $firstVisibleTextNode = null;

        var viewportLeft = this.$viewport.offset().left;
        var viewportRight = viewportLeft + this.$viewport.width();

        // Rationale: The intention here is to get a list of all the text nodes in the document, after which we'll
        //   reduce this to the subset of text nodes that is visible on the page. We'll then select one text node
        //   for which we can create a character offset CFI. This CFI will then refer to a "last position" in the
        //   EPUB, which can be used if the reader re-opens the EPUB.
        // REFACTORING CANDIDATE: The "audiError" check is a total hack to solve a problem for a particular epub. This
        //   issue needs to be addressed.
        $elements = $("body", this.getRootElement()).find(":not(iframe)").contents().filter(function () {
            if (this.nodeType === 3 && !$(this).parent().hasClass("audiError")) {
                return true;
            } else {
                return false;
            }
        });


        // Find the first visible text node
        $.each($elements, function() {

            var POSITION_ERROR_MARGIN = 5;
            var $textNodeParent = $(this).parent();
            var elementLeft = $textNodeParent.offset().left;
            var elementRight = elementLeft + $textNodeParent.width();
            var nodeText;

            // Correct for minor right and left position errors
            elementLeft = Math.abs(elementLeft) < POSITION_ERROR_MARGIN ? 0 : elementLeft;
            elementRight = Math.abs(elementRight - viewportRight) < POSITION_ERROR_MARGIN ? viewportRight : elementRight;

            // Heuristic to find a text node with actual text
            nodeText = this.nodeValue.replace(/\n/g, "");
            nodeText = nodeText.replace(/ /g, "");

            if (elementLeft <= viewportRight
                && elementRight >= viewportLeft
                && nodeText.length > 10) { // 10 is so the text node is actually a text node with writing

                $firstVisibleTextNode = $(this);

                // Break the loop
                return false;
            }
        });

        return $firstVisibleTextNode;
    },

    getFirstVisibleElementCfi: function() {

        var $visibleTextNode = this.findVisibleTextNode();
        if(!$visibleTextNode) {
            console.log("Could not generate CFI for non-text node as first visible element on page");
            return;
        }

        //Temp ZZZ
        var cfi = EPUBcfi.Generator.generateCharacterOffsetCFIComponent($visibleTextNode[0], 0);

        //dosent work return NaN at the end of cfi
//        var cfi = EPUBcfi.Generator.generateElementCFIComponent($visibleTextNode[0]);

        var $parent = $visibleTextNode.parent();

        var invisiblePart = this.$viewport.offset().top - $parent.offset().top;

        var percent = 0;
        var height = $parent.height();
        if(invisiblePart > 0 && height > 0) {
             percent = Math.floor(invisiblePart * 100 / $parent.height());
        }

        if(cfi[0] == "!") {
            cfi = cfi.substring(1);
        }

        return cfi.replace(":0", "@0:" + percent);


//        if($visibleTextNode) {
//            var characterOffset = this.findVisibleCharacterOffset($visibleTextNode);
//            return EPUBcfi.Generator.generateCharacterOffsetCFIComponent($visibleTextNode[0], characterOffset);
//        }


    },



    // Currently for left-to-right pagination only
    findVisibleCharacterOffset : function($textNode) {

        var $parentNode;
        var elementTop;
        var $document;
        var documentTop;
        var documentBottom;
        var percentOfTextOffPage;
        var characterOffset;

        // Get parent
        $parentNode = $textNode.parent();

        // get document
        $document = $(this.el);

        // Find percentage of visible node on page
        documentTop = $document.position().top;
        documentBottom = documentTop + $document.height();

        elementTop = $parentNode.offset().top;

        // Element overlaps top
        if (elementTop < documentTop) {

            percentOfTextOffPage = Math.abs(elementTop - documentTop) / $parentNode.height();
            var characterOffsetByPercent = Math.ceil(percentOfTextOffPage * $textNode[0].length);
            characterOffset = Math.ceil(0.5 * ($textNode[0].length - characterOffsetByPercent)) + characterOffsetByPercent;
        }
        else if (elementTop >= documentTop && elementTop <= documentBottom) {
            characterOffset = 1;
        }
        else if (elementTop < documentBottom) {
            characterOffset = 1;
        }

        return characterOffset;
    },

    getPageForElementCfi: function(cfi) {

        var contentDoc = this.$el[0].contentDocument;
        var cfiParts = this.splitCfi(cfi);

        var wrapedCfi = "epubcfi(" + cfiParts.cfi + ":0" + ")";
        var result = EPUBcfi.Interpreter.getTextTerminusInfoWithPartialCFI(wrapedCfi, contentDoc);

        if(!result || !result.textNode) {
            console.log("Can't find element for CFI: " + cfi);
            return;
        }

        var $element = $(result.textNode).parent();

        var pagination = this.options.paginationInfo;

        var elementOffset = $element.offset();
        var elLeft = elementOffset.left + pagination.pageOffset;

        var page = Math.floor(elLeft / (pagination.columnWidth + pagination.columnGap));

        var posInElement = elementOffset.top + cfiParts.y * $element.height() / 100
        var posOverflow = posInElement - (this.$viewport.offset().top + this.$viewport.height());

        if(posOverflow > 0) {
            page += Math.ceil(posOverflow / this.$viewport.height())
        }

        return page;
    },

    splitCfi: function(cfi) {

        var ret = {
            cfi: "",
            x: 0,
            y: 0
        };

        var ix = cfi.indexOf("@");

        if(ix != -1) {
            var terminus = cfi.substring(ix + 1);

            var colIx = terminus.indexOf(":");
            if(colIx != -1) {
                ret.x = parseInt(terminus.substr(0, colIx));
                ret.y = parseInt(terminus.substr(colIx + 1));
            }
            else {
                console.log("Unexpected terminating step format");
            }

            ret.cfi = cfi.substring(0, ix);
        }
        else {

            ret.cfi = cfi;
        }

        return ret;
    }

//    getPageForElementCfi: function(cfi) {
//
//        var contentDoc = this.$el[0].contentDocument;
//
//        var result = EPUBcfi.Interpreter.getTextTerminusInfoWithPartialCFI(cfi, contentDoc);
//
//        if(!result || !result.textNode) {
//            console.log("Can't find element for CFI: " + cfi);
//            return;
//        }
//
//        var pagination = this.options.paginationInfo;
//        var elLeft = $(result.textNode).offset().left + pagination.pageOffset;
//
//        var page = Math.floor(elLeft / (pagination.columnWidth + pagination.columnGap));
//
//        return page;
//    }

//    getPageForElementCfi: function(cfi) {
//
//        var contentDoc = this.$el[0].contentDocument;
//
//        var tmpDiv = contentDoc.createElement("div");
//        tmpDiv.setAttribute("id", "_tmp_mark");
//
//        var element = EPUBcfi.Interpreter.getTargetElement(cfi, contentDoc);
//
//        if(!element) {
//            console.log("Can't find element for CFI: " + cfi);
//            return;
//        }
//
//        var injectedEl = EPUBcfi.Interpreter.injectElement(cfi, contentDoc, tmpDiv);
//
//        var pagination = this.options.paginationInfo;
//        var elLeft = $(injectedEl).offset().left + pagination.pageOffset;
//
//        var page = Math.floor(elLeft / (pagination.columnWidth + pagination.columnGap));
//
//        return page;
//    }



});