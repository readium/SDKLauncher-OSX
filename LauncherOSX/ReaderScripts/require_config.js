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


require.config({

    //xhtml: true, //document.createElementNS()
    
    /* http://requirejs.org/docs/api.html#config-waitSeconds */
    waitSeconds: 0,
    
    paths: {

        text: 'text',
        
		jquery: 'lib/jquery',
        
        underscore: 'lib/underscore.min',

        eventEmitter: 'eventemitter3',

        jquerySizes: 'lib/jquery.sizes',

        epubCfi: 'lib/epub_cfi',
        domReady : 'domReady',

        rangy : 'lib/rangy/rangy',
        "rangy-core" : 'lib/rangy/rangy-core',
        "rangy-textrange" : 'lib/rangy/rangy-textrange',
        "rangy-highlighter" : 'lib/rangy/rangy-highlighter',
        "rangy-cssclassapplier" : 'lib/rangy/rangy-cssclassapplier',
        "rangy-position" : 'lib/rangy/rangy-position',
        
        epubReadingSystem: 'epubReadingSystem.js',
        HostAppFeedback: 'host_app_feedback.js',
        
        Bootstrapper: 'Bootstrapper'
    },

    packages: [

        {
            name: 'readium-plugins',
            location: 'plugins',
            main: '_loader'
        },
        {
            name: 'epub-renderer',
            location: 'js'
        },
        {
            name: 'URIjs',
            location: 'URIjs',
            main: 'URI'
        }
    ],


    shim: {

        'rangy-core': {
             deps: ["domReady"],
             exports: "rangy", // global.rangy
             init: function(domReady) {
                 var rangi = this.rangy;
            domReady(function(){
                rangi.init();
            });
            return this.rangy;
        }
       },
       'rangy-textrange': {
         deps: ["rangy-core"],
         exports: "rangy.modules.TextRange"
       },
       'rangy-highlighter': {
         deps: ["rangy-core"],
         exports: "rangy.modules.Highlighter"
       },
       'rangy-cssclassapplier': {
         deps: ["rangy-core"],
         exports: "rangy.modules.ClassApplier"
       },
       'rangy-position': {
         deps: ["rangy-core"],
         exports: "rangy.modules.Position"
       },
        
       /*
       'rangy/rangy-serializer': {
         deps: ["rangy/rangy-core"],
         exports: "rangy.modules.Serializer"
       },
       'rangy/rangy-selectionsaverestore': {
         deps: ["rangy/rangy-core"],
         exports: "rangy.modules.SaveRestore"
       },
       */
       /*
        console_shim: {
            exports: 'console_shim'
        },
       */
        underscore: {
            exports: '_'
        },

        epubCFI: {
            deps: ['jquery'],
            exports: ['epubCFI']
        },

        jquerySizes: {
            deps: ['jquery'],
            exports: 'jquerySizes'
        },

    },

    exclude: ['jquery', 'underscore', 'URIjs']
});
