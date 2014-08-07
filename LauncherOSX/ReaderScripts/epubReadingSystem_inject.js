(function inject_epubReadingSystem() {

    if (!window.readium_set_epubReadingSystem_DO) {

        //Phase 1
        window.readium_set_epubReadingSystem = function (obj) {

            window.navigator.epubReadingSystem = obj;

            window.readium_set_epubReadingSystem = undefined;
//
//            setTimeout(function () {
//                console.log(JSON.stringify(window.navigator.epubReadingSystem));
//                if (window.navigator.epubReadingSystem.hello)
//                {
//                    console.log("LOCAL CALL navigator.epubReadingSystem.hello: "+window.location.href);
//                    window.navigator.epubReadingSystem.hello(window.location.href);
//                }
//            }, 1000);
        };
    }
    else {
        //Phase 2
        for (var i = 0; i < window.frames.length; i++) {
            var iframe = window.frames[i];

            if (iframe.readium_set_epubReadingSystem) {
                iframe.readium_set_epubReadingSystem(window.navigator.epubReadingSystem);
            }
        }
    }

})();