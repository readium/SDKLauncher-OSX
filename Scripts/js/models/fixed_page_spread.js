

ReadiumSDK.Models.Spread = function(spine) {

    this.spine = spine;

    this.leftItem = undefined;
    this.rightItem = undefined;
    this.centerItem = undefined;

    this.openFirst = function() {

        if( this.spine.items.length == 0 ) {
            this.resetItems();
        }
        else {
            this.openItem(this.spine.first());
        }
    }

    this.openLast = function() {

        if( this.spine.items.length == 0 ) {
            this.resetItems();
        }
        else {
            this.openItem(this.spine.last());
        }
    };

    this.openItem = function(item) {

        this.resetItems();
        this.setItem(item);

        var neighbourItem = this.getNeighbourItem(item);

        if(neighbourItem) {
            this.setItem(neighbourItem);
        }
    };

    this.resetItems = function() {

        this.leftItem = undefined;
        this.rightItem = undefined;
        this.centerItem = undefined;

    };

    this.setItem = function(item) {

        if(item.spread == "left") {
            this.leftItem = item;
        }
        else if (item.spread == "right") {
            this.rightItem = item;
        }
        else {
            this.centerItem = item;
        }
    };

    this.openNext = function() {

        var items = this.validItems();

        if(items.length == 0) {

            this.openFirst();
        }
        else {

            var nextItem = this.spine.nextItem(items[items.length - 1]);
            if(nextItem) {

                this.openItem(nextItem);
            }
        }
    }

    this.openPrev = function() {

        var items = this.validItems();

        if(items.length == 0) {
            this.openLast();
        }
        else {

            var prevItem = this.spine.prevItem(items[0]);
            if(prevItem) {

                this.openItem(prevItem);

            }
        }
    };

    this.openLeft = function() {

        if(this.spine.isRightToLeft()) {
            this.openNext();
        }
        else {
            this.openPrev();
        }
    };

    this.openRight = function() {

        if(this.spine.isLeftToRight()) {
            this.openNext();
        }
        else {
            this.openPrev();
        }

    }

    this.validItems = function() {

        var arr = [];

        if(this.leftItem) arr.push(this.leftItem);
        if(this.rightItem) arr.push(this.rightItem);
        if(this.centerItem) arr.push(this.centerItem);

        arr.sort(function(a, b) {
            return a.index - b.index;
        });

        return arr;
    }

    this.getNeighbourItem = function(item) {

        var neighbourItem = undefined;

        if(item.spread == "left") {

            neighbourItem = this.spine.isRightToLeft() ? this.spine.prevItem(item) : this.spine.nextItem(item);
        }
        else if(item.spread == "right") {

            neighbourItem = this.spine.isRightToLeft() ? this.spine.nextItem(item) : this.spine.prevItem(item);
        }

        if(neighbourItem && (neighbourItem.spread == item.spread || neighbourItem.spread == "center") ) {

            neighbourItem = undefined;
        }

        return neighbourItem;
    };

};