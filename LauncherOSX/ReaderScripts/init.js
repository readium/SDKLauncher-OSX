//  Copyright (c) 2014 Readium Foundation and/or its licensees. All rights reserved.
//  
//  Redistribution and use in source and binary forms, with or without modification, 
//  are permitted provided that the following conditions are met:
//  1. Redistributions of source code must retain the above copyright notice, this 
//  list of conditions and the following disclaimer.
//  2. Redistributions in binary form must reproduce the above copyright notice, 
//  this list of conditions and the following disclaimer in the documentation and/or 
//  other materials provided with the distribution.
//  3. Neither the name of the organization nor the names of its contributors may be 
//  used to endorse or promote products derived from this software without specific 
//  prior written permission.

define(['jquery', 'Bootstrapper', 'epub-renderer/views/reader_view', 'text!epubReadingSystem', 'text!HostAppFeedback'], function ($, Bootstrapper, ReaderView, epubReadingSystem, HostAppFeedback) {

// TODO YUK!!!! (eval())

//    console.debug(epubReadingSystem);
    eval(epubReadingSystem);
    
//    console.debug(HostAppFeedback);
    eval(HostAppFeedback);
    
    $(document).ready(function () {
        "use strict";

        //var prefix = (self.location && self.location.origin && self.location.pathname) ? (self.location.origin + self.location.pathname + "/..") : "";

        ReadiumSDK.reader = new ReaderView(
        {
            needsFixedLayoutScalerWorkAround: true,
            el:"#viewport",
            annotationCSSUrl: '/readium_Annotations.css' //prefix + '/css/annotations.css'
        });

        //Globals.emit(Globals.Events.READER_INITIALIZED, ReadiumSDK.reader);
        ReadiumSDK.emit(ReadiumSDK.Events.READER_INITIALIZED, ReadiumSDK.reader);
    });
    
});