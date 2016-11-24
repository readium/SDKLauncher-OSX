//
//  LOXAppDelegate.m
//  LauncherOSX
//
//  Created by Boris Schneiderman.
//
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
//  
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
//  IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
//  INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
//  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
//  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
//  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE 
//  OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED 
//  OF THE POSSIBILITY OF SUCH DAMAGE.

#import "LOXAppDelegate.h"
#import "LOXePubSdkApi.h"

#import <ePub3/container.h>
#import "LOXUserData.h"
#import "LOXBook.h"
#import "LOXBookmarksController.h"
#import "LOXBookmark.h"
#import "LOXSpineItem.h"
#import "LOXTocViewController.h"
#import "LOXSpine.h"
#import "LOXPackage.h"
#import "LOXCurrentPagesInfo.h"
#import "LOXPageNumberTextController.h"
#import "LOXPreferencesController.h"
#import "LOXUtil.h"
#import "LOXMediaOverlay.h"
#import "LOXMediaOverlayController.h"

#import "RDLCPService.h"
#import <platform/apple/src/lcp.h>

#import <LcpContentModule.h>

#include <ePub3/content_module_exception.h>

using namespace ePub3;

class LcpCredentialHandler : public lcp::ICredentialHandler
{
private:
    LOXAppDelegate* _self;
public:
    LcpCredentialHandler(LOXAppDelegate* self) {
        _self = self;
    }
    
    void decrypt(lcp::ILicense *license) {
        LCPLicense* lcpLicense = [[LCPLicense alloc] initWithLicense:license];
        [_self decrypt:lcpLicense];
    }
};

class LcpStatusDocumentHandler : public lcp::IStatusDocumentHandler
{
private:
    LOXAppDelegate* _self;
public:
    LcpStatusDocumentHandler(LOXAppDelegate* self) {
        _self = self;
    }
    
    void process(lcp::ILicense *license) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            //license->setStatusDocumentProcessingFlag(false);
            //return;
            
            [_self openDocumentWithCurrentPath];
        });
    }
};

//FOUNDATION_EXPORT
extern NSString *const LOXPageChangedEvent;

@interface LOXAppDelegate ()
#if ENABLE_NET_PROVIDER
<LCPAcquisitionDelegate>
#endif //ENABLE_NET_PROVIDER

- (NSString *)selectFile;

- (LOXBook *)findOrCreateBookForCurrentPackageWithPath:(NSString *)path;

- (void)onPageChanged:(id)onPageChanged;

- (bool)openDocumentWithPath:(NSString *)path;

@end



@implementation LOXAppDelegate {
@private

    LOXePubSdkApi *_epubApi;
    LOXUserData *_userData;
    LOXBook*_currentBook;
    LOXPackage *_package;
    
    NSString* _currentLCPLicensePath;
    NSString* _currentOpenChosenPath;
}

@synthesize currentPagesInfo = _currentPagesInfo;

- (LOXPreferences *)getPreferences
{
    return _userData.preferences;
}

- (id)init
{
    self = [super init];
    if (self) {

        _currentPagesInfo = [[LOXCurrentPagesInfo alloc] init];
        _userData = [[LOXUserData alloc] init];
    }

    return self;
}


//- (void)containerRegisterContentFilters
//{
//    [[RDLCPService sharedService] registerContentFilter];
//}

-(void) awakeFromNib
{
    _epubApi = [[LOXePubSdkApi alloc] init];
    
    
    lcp::ICredentialHandler * credentialHandler = new LcpCredentialHandler(self);
    lcp::IStatusDocumentHandler * statusDocumentHandler = new LcpStatusDocumentHandler(self);
    
    [[RDLCPService sharedService] registerContentModule:credentialHandler statusDocumentHandler:statusDocumentHandler];

//    if ([self respondsToSelector:@selector(containerRegisterContentFilters:)]) {
//        [self containerRegisterContentFilters];
//    }
//    
//    //Content Modules for each DRM library, if any, should be registered in the function.
//    if ([self respondsToSelector:@selector(containerRegisterContentModules:)]) {
//        [self containerRegisterContentModules];
//    }

    self.spineViewController.currentPagesInfo = _currentPagesInfo;
    self.webViewController.currentPagesInfo = _currentPagesInfo;
    self.pageNumController.currentPagesInfo = _currentPagesInfo;
    self.spineViewController.selectionChangedLiscener = self.webViewController;

    self.preferencesController.webViewController = self.webViewController;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onPageChanged:)
                                                 name:LOXPageChangedEvent
                                               object:nil];

}

- (void)onPageChanged:(id)onPageChanged
{
    LOXBookmark *bookmark = [self createBookmark];

    if(bookmark) {

        bookmark.title = @"lastOpenPage";
        _currentBook.lastOpenPage = bookmark;
    }
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
    return YES;
}


- (IBAction)openDocument:(id)sender;
{
    NSString *path = [self selectFile];

    if (path == nil) {
        return;
    }

    _currentOpenChosenPath = path;
    [self openDocumentWithPath:path];
}

- (bool)openDocumentWithCurrentPath
{
    return [self openDocumentWithPath:_currentOpenChosenPath];
}

- (bool)openDocumentWithPath:(NSString *)path //error:(NSError **)error
{
    if ([_epubApi canOpenFile:path]) { // EPUB
        
        try {

            _package = [_epubApi openFile:path];

            if(!_package) {
                return NO;
            }

// NOW WITH CONTENT MODULE
//            NSError *error;
//            if (![self loadLCPLicense:&error])
//                return NO;
//            
//            if (self.license && !self.license.isDecrypted) {
//                [self decryptLCPLicense];
//            }
            
            [self.tocViewController setPackage: _package];
            [self.spineViewController setPackage:_package];

            _currentBook = [self findOrCreateBookForCurrentPackageWithPath:path];
            _currentBook.dateOpened = [NSDate date];
            [self.bookmarksController setBook:_currentBook];

            [[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:[NSURL fileURLWithPath:path]];

            [self.window setTitle:[path lastPathComponent]];

            [self.webViewController openPackage:_package onPage:_currentBook.lastOpenPage];

            return YES;
        }
        catch (NSException *e) {
            [LOXUtil reportError:[e reason]];
        }
        catch (ePub3::ContentModuleExceptionDecryptFlow& e) {
            // NoOP
        }
        catch (std::exception& e) { // includes ePub3::ContentModuleException
            
            auto msg = e.what();
            
            std::cout << msg << std::endl;
            
            [LOXUtil reportError:[NSString stringWithUTF8String:msg]];
        }
        catch (...) {
            [LOXUtil reportError:@"unknown exceprion"];
        }
    } else if ([path.pathExtension.lowercaseString isEqual:@"lcpl"]) { // LCPL => acquire EPUB (download)
        
        BOOL success = NO;
        NSError *error;
        success = [self acquirePublicationWithLicense:path error:&error];
        
        
        if (success) {
            NSString *title = @"LCP EPUB acquisition in progress...";
            
            NSString *message = @"Wait...";
            
            [_epubApi presentAlertWithTitle:title message:message];
        } else {
            NSString *title = @"LCP EPUB acquisition failure";
            
            NSString *message = (error != nil) ? [NSString stringWithFormat:@"%@ (%ld)", error.domain, (long)error.code] : @"UNKNOWN ERROR";
            
            [_epubApi presentAlertWithTitle:title message:message];
        }
    }
    
    return NO;
}

- (LOXBook *)findOrCreateBookForCurrentPackageWithPath:(NSString *)path
{
    LOXBook * book = [_userData findBookWithId:_package.packageId fileName:[path lastPathComponent]];

    if(!book) {
        book = [[LOXBook alloc] init];
        book.filePath = path;
        book.packageId = _package.packageId;
        book.name = _package.title;
        [_userData addBook: book];
    }

    return book;
}

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename
{
    _currentOpenChosenPath = filename;
    return [self openDocumentWithPath:filename];
}




- (NSString *)selectFile
{
    NSOpenPanel *dlg = [NSOpenPanel openPanel];

    NSArray *fileTypesArray = [_epubApi supportedFileExtensions]; //[NSArray arrayWithObjects:@"epub", @"lcpl", nil];
    
    [dlg setCanChooseFiles:YES];
    [dlg setAllowedFileTypes:fileTypesArray];
    [dlg setAllowsMultipleSelection:FALSE];

    if ([dlg runModal] == NSOKButton) {
        NSURL *url = [dlg URL];

        NSString* p = [url path];
        return p;
    }

    return nil;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    [_userData save];

    return NSTerminateNow;
}


- (LOXBookmark *)createBookmark
{

    LOXBookmark *bookmark = [self.webViewController createBookmark];
    if(!bookmark) {
        return nil;
    }

    LOXSpineItem *spineItem = [_package.spine getSpineItemWithId:bookmark.idref];
    if(!spineItem) {
        return nil;
    }

     bookmark.basePath = spineItem.href;
    bookmark.spineItemCFI = [_package getCfiForSpineItem: spineItem];

    return bookmark;
}


- (void)openBookmark:(LOXBookmark *)bookmark
{
    [self.webViewController openSpineItem:bookmark.idref elementCfi:bookmark.contentCFI];
}

- (void)openContentUrl:(NSString *)contentRef fromSourceFileUrl:(NSString*) sourceRef
{
   [self.webViewController openContentUrl:contentRef fromSourceFileUrl:sourceRef];
}

- (void)onReaderInitialized
{
   [self.webViewController updateSettings:_userData.preferences];
}


- (IBAction)showPreferences:(id)sender
{
    [self.preferencesController showPreferences:_userData.preferences];
}
//
//
//- (BOOL)loadLCPLicense:(NSError **)error
//{
//    NSString *licenseJSON = [_epubApi contentsOfFileAtPath:@"META-INF/license.lcpl" encoding:NSUTF8StringEncoding];
//    if (licenseJSON) {
//        _license = [[RDLCPService sharedService] openLicense:licenseJSON error:error];
//        return (_license != nil);
//    }
//    
//    return YES;
//}

- (void)decrypt:(LCPLicense*)lcpLicense {
    _license = lcpLicense;
    [self decryptLCPLicense];
}


- (void)decryptLCPLicense {
    
    NSString *lcpPass = [_epubApi presentAlertWithInput:@"LCP passphrase" inputDefaultText:@"LCP passphrase" message:@"Please enter LCP %@", @"passphrase"];

    if (lcpPass != nil) {
        NSError *error;
        BOOL decrypted = [[RDLCPService sharedService] decryptLicense:self.license passphrase:lcpPass error:&error];
        if (!decrypted) {
            if (error.code != LCPErrorDecryptionLicenseEncrypted && error.code != LCPErrorDecryptionUserPassphraseNotValid) {
                [_epubApi presentAlertWithTitle:@"LCP Error" message:@"%@ (%d)", error.domain, error.code];
            }
            [self decryptLCPLicense];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
               [self openDocumentWithPath:_currentOpenChosenPath];
            });
        }
    }
}
//////////////////////////////////////////////////////////////////////
#pragma mark - LCP Acquisition

- (BOOL)acquirePublicationWithLicense:(NSString *)licensePath error:(NSError **)error {
    RDLCPService *lcp = [RDLCPService sharedService];
    NSString *licenseJSON = [NSString stringWithContentsOfFile:licensePath encoding:NSUTF8StringEncoding error:NULL];
    
    LCPLicense *license = [lcp openLicense:licensePath licenseJSON:licenseJSON error:error];
    if (!license)
        return NO;
    
    NSString *fileName = [NSString stringWithFormat:@"%@_%@", [[NSProcessInfo processInfo] globallyUniqueString], @"lcp.epub"];
    NSURL *downloadFileURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:fileName]];
    
#if ENABLE_NET_PROVIDER
    LCPAcquisition *acquisition = [lcp createAcquisition:license publicationPath:downloadFileURL.path error:error];
    if (!acquisition)
        return NO;
#endif //ENABLE_NET_PROVIDER
    _currentLCPLicensePath = licensePath;
#if ENABLE_NET_PROVIDER
    [acquisition startWithDelegate:self];
#endif //ENABLE_NET_PROVIDER
    return YES;
}

#if ENABLE_NET_PROVIDER
- (void)endAcquisition:(LCPAcquisition *)acquisition
{
    NSLog([NSString stringWithFormat:@"LCP EPUB acquisition end [%@]=> [%@]", _currentLCPLicensePath, acquisition.publicationPath]);
    _currentLCPLicensePath = nil;
}

- (void)lcpAcquisitionDidCancel:(LCPAcquisition *)acquisition
{
    [self endAcquisition:acquisition];
}

- (void)lcpAcquisition:(LCPAcquisition *)acquisition didProgress:(float)progress
{
    NSLog([NSString stringWithFormat:@"LCP EPUB acquisition progress: %f percent [%@]=> [%@]", progress * 100.0, _currentLCPLicensePath, acquisition.publicationPath]);
}

- (void)lcpAcquisition:(LCPAcquisition *)acquisition didEnd:(BOOL)success error:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (!success) {
            [_epubApi presentAlertWithTitle:@"LCP EPUB acquisition failed" message:@"%@ (%d) [%@]=> [%@]", error.domain, error.code, _currentLCPLicensePath, acquisition.publicationPath];
            
            [self endAcquisition:acquisition];
            
            return;
        }
        
        NSString *title = @"LCP EPUB acquisition finished";
        
        NSString *message = [NSString stringWithFormat:@"EPUB: [%@] => [%@]", _currentLCPLicensePath, acquisition.publicationPath];
        
        [_epubApi presentAlertWithTitle:title message:message];
        
        [self endAcquisition:acquisition];
        
        _currentOpenChosenPath = acquisition.publicationPath;
        
        [self openDocumentWithPath:_currentOpenChosenPath];
    });
    
//    
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
//        if (success) {
//            // move the downloaded publication to the Documents/ folder, using
//            // the suggested filename if any
//            
//            NSString *filename = (acquisition.suggestedFilename.length > 0) ? acquisition.suggestedFilename : [_currentLCPAcquisitionPath lastPathComponent];
//            filename = [NSString stringWithFormat:@"%@.epub", [filename stringByDeletingPathExtension]];
//            
//            NSURL *documentsURL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
//            NSString *destinationPath = [[documentsURL URLByAppendingPathComponent:filename] path];
//            
//            [[NSFileManager defaultManager] moveItemAtPath:acquisition.publicationPath toPath:destinationPath error:NULL];
//            
//            [[NSFileManager defaultManager] removeItemAtPath:_currentLCPAcquisitionPath error:NULL];
//        }
//   
//    });
}

#endif //ENABLE_NET_PROVIDER

@end
