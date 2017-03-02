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

#import "LCPStatusDocumentProcessing_DeviceIdManager.h"

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
            
            LCPLicense* lcpLicense = [[LCPLicense alloc] initWithLicense:license];
            [_self launchStatusDocumentProcessing:lcpLicense];
        });
    }
};

//FOUNDATION_EXPORT
extern NSString *const LOXPageChangedEvent;

@interface LOXAppDelegate ()
#if ENABLE_NET_PROVIDER_ACQUISITION
<StatusDocumentProcessingListener, LCPAcquisitionDelegate>
#else
<StatusDocumentProcessingListener, NSURLSessionDataDelegate>
#endif //ENABLE_NET_PROVIDER_ACQUISITION

- (NSString *)selectFile;

- (LOXBook *)findOrCreateBookForCurrentPackageWithPath:(NSString *)path;

- (void)onPageChanged:(id)onPageChanged;

- (bool)openDocumentWithPath:(NSString *)path;

- (void)onStatusDocumentProcessingComplete_:(LCPStatusDocumentProcessing*)lsd;


-(void)fetchAndDisplayEpubInfo:(NSString*)path;
-(void)displayEpubInfo:(ContainerPtr)containerPtr;

//@property (strong, nonatomic) NSURLSession *session;

@end



@implementation LOXAppDelegate {
@private

    LOXePubSdkApi *_epubApi;
    LOXUserData *_userData;
    LOXBook*_currentBook;
    LOXPackage *_package;
    
    NSString* _currentLCPLicensePath;
    NSString* _currentOpenChosenPath;
    
    LCPStatusDocumentProcessing * _statusDocumentProcessing;
    NSAlert * _alertStatusDocumentProcessing;
}

@synthesize currentPagesInfo = _currentPagesInfo;
//@synthesize currentOpenChosenPath = _currentOpenChosenPath;

NSString* TASK_DESCRIPTION_LCP_EPUB_DOWNLOAD = @"LCP_EPUB_DOWNLOAD";

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

    [self fetchAndDisplayEpubInfo:path];
    
    _currentOpenChosenPath = path;
    
    [self performSelectorOnMainThread:@selector(openDocumentWithPath:) withObject:path waitUntilDone:NO];
//        dispatch_async(dispatch_get_main_queue(), ^{
//    [self openDocumentWithPath:path];
//        });

}


-(void)fetchAndDisplayEpubInfo:(NSString*)path
{
    if ([_epubApi canOpenFile:path]) { // EPUB
        
        try {
            ContainerPtr containerPtr = Container::OpenContainerForContentModule([path UTF8String], true);
            [self displayEpubInfo:containerPtr];
        }
        catch (NSException *e) {
            // NoOP
        }
        catch (ePub3::ContentModuleExceptionDecryptFlow& e) { // should never occur, because call to OpenContainerForContentModule(), not OpenContainer()
            
            // NoOP
        }
        catch (std::exception& e) { // includes ePub3::ContentModuleException
            // NoOP
        }
        catch (...) {
            // NoOP
        }
    }
}

-(void)displayEpubInfo:(ContainerPtr)containerPtr
{
    PackagePtr packagePtr = containerPtr->DefaultPackage();
    if (packagePtr != nullptr) {
        
        // Safe access, never encrypted
        ePub3::string title = packagePtr->FullTitle(false);
        NSString *alertTitle = @"EPUB title";
        NSString *alertMessage = [NSString stringWithUTF8String:title.c_str()];
        [_epubApi presentAlertWithTitle:alertTitle message:alertMessage];
        
        // Guaranteed safe access in LCP
        //... but we check for EncryptionInfo just in case
        // (other DRM schemes may not guarantee clear / plaintext cover image)
        ManifestItemPtr coverImageManifestItemPtr = packagePtr->CoverManifestItem();
        if (coverImageManifestItemPtr != nullptr) {
            ePub3::string coverImagePath = coverImageManifestItemPtr->AbsolutePath();

            if (coverImageManifestItemPtr->GetEncryptionInfo() == nullptr) {

                unique_ptr<ByteStream> byteStream = coverImageManifestItemPtr->Reader();
                if (byteStream != nullptr && byteStream.get() != nullptr) {
                    size_t toRead = byteStream->BytesAvailable();
                    
                    uint8_t *buffer = nullptr;
                    size_t didRead = byteStream->ReadAllBytes((void **) &buffer);
                    
                    byteStream->Close();
                    
                    if (toRead != didRead) {
                        bool breakpoint = true;
                    }
                    
                    if (buffer != nullptr && didRead > 0) {
                        NSData *data = [NSData dataWithBytes:buffer length:didRead];
                        NSImage *img = [[NSImage alloc] initWithData:data];
                        
                        
                        NSAlert *alert = [[NSAlert alloc] init];
                        [alert setMessageText:@"EPUB cover image"];
                        [alert setInformativeText:[NSString stringWithUTF8String:coverImagePath.c_str()]];
                        [alert setIcon:img];
                        
                        [alert addButtonWithTitle:@"OK"];
                        // [alert addButtonWithTitle:@"SECOND"];
                        
                        switch ([alert runModal]) {
                            case NSAlertFirstButtonReturn: {
                                // OK
                                break;
                            }
                            case NSAlertSecondButtonReturn: {
                                // SECOND
                                break;
                            }
                            default:
                                break;
                        }
                        
                    }
                }
            } else {
                NSString *alertTitle = @"EPUB cover image (encrypted)";
                NSString *alertMessage = [NSString stringWithUTF8String:coverImagePath.c_str()];
                [_epubApi presentAlertWithTitle:alertTitle message:alertMessage];
            }
        }
    }
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

            [self performSelectorOnMainThread:@selector(alertModal_downloadInProgress:) withObject:nil waitUntilDone:NO];
            
        } else {
            NSString *title = @"LCP EPUB acquisition failure";
            
            NSString *message = (error != nil) ? [NSString stringWithFormat:@"%@ (%ld)", error.domain, (long)error.code] : @"UNKNOWN ERROR";
            
            [_epubApi presentAlertWithTitle:title message:message];
        }
    }
    
    return NO;
}

- (void)alertModal_downloadInProgress:(NSObject*)obj {
    
    //dispatch_async(dispatch_get_main_queue(), ^{
        
        NSString *title = @"LCP EPUB acquisition in progress...";
        
        NSString *message = @"(close this dialog when download is finished)";
        
        //[_epubApi presentAlertWithTitle:title message:message];
        
        NSAlert *downloadAlert = [[NSAlert alloc] init];
        [downloadAlert setMessageText:title];
        [downloadAlert setInformativeText:message];
        
        [downloadAlert addButtonWithTitle:@"OK"];
        // [downloadAlert addButtonWithTitle:@"SECOND"];
        //
        //    [downloadAlert beginWithCompletionHandler:^(NSInteger result) {
        //
        //    }];
        switch ([downloadAlert runModal]) {
            case NSAlertFirstButtonReturn: {
                // OK
                break;
            }
            case NSAlertSecondButtonReturn: {
                // SECOND
                break;
            }
            default:
                break;
        }
        
    //});
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
    [self fetchAndDisplayEpubInfo:filename];
    
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
//        _license = [[RDLCPService sharedService] openLicense:"@@ licenseJSON:licenseJSON error:error];
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
    
    // Note: licensePath == _currentOpenChosenPath
    
    RDLCPService *lcp = [RDLCPService sharedService];
    
    NSString *licenseJSON = [NSString stringWithContentsOfFile:licensePath encoding:NSUTF8StringEncoding error:NULL];
    
    LCPLicense *license = [lcp openLicense:@"" licenseJSON:licenseJSON error:error];
    if (!license)
        return NO;

#if ENABLE_NET_PROVIDER_ACQUISITION
    
    //    NSString *fileName = [NSString stringWithFormat:@"%@_%@", [[NSProcessInfo processInfo] globallyUniqueString], @"lcp.epub"];
    //    NSURL *downloadFileURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:fileName]];
    
//    NSString *folderPath = [licensePath stringByDeletingLastPathComponent];
//    NSString *fileName = [folderPath stringByAppendingPathComponent:xxx];
    
    NSString *fileName = [NSString stringWithFormat:@"%@%@", licensePath, @".epub"];
    
    NSURL *downloadFileURL = [NSURL fileURLWithPath:fileName];
    
    
    LCPAcquisition *acquisition = [lcp createAcquisition:license publicationPath:downloadFileURL.path error:error];
    if (!acquisition)
        return NO;
#endif //ENABLE_NET_PROVIDER_ACQUISITION
    
    _currentLCPLicensePath = licensePath; //_currentOpenChosenPath
    
#if ENABLE_NET_PROVIDER_ACQUISITION
    [acquisition startWithDelegate:self];
#else
    
    //_currentOpenChosenPath
    //_currentLCPLicensePath
    NSURL *sourceUrl = [NSURL URLWithString:license.linkPublication];
    
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    NSURLSession * session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil]; //[NSOperationQueue mainQueue] // [[NSThread currentThread] isMainThread]
    
    NSURLSessionDataTask *task = [session dataTaskWithURL:sourceUrl];
    task.taskDescription = TASK_DESCRIPTION_LCP_EPUB_DOWNLOAD;
//        id identifier = @(task.taskIdentifier);
//        self.requests[identifier] = [NSValue valueWithPointer:request];
//        self.callbacks[identifier] = [NSValue valueWithPointer:callback];
        [task resume];
    
#endif //ENABLE_NET_PROVIDER_ACQUISITION
    return YES;
}

#if ENABLE_NET_PROVIDER_ACQUISITION
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
        
//        _currentOpenChosenPath = acquisition.publicationPath;
        _currentOpenChosenPath = [NSString stringWithFormat:@"%@%@", _currentLCPLicensePath, @".epub"];
       
       if ([[NSFileManager defaultManager] fileExistsAtPath:_currentOpenChosenPath]) {
           [[NSFileManager defaultManager] removeItemAtPath:_currentOpenChosenPath error:NULL];
       }
        
        [[NSFileManager defaultManager] moveItemAtPath:acquisition.publicationPath toPath:_currentOpenChosenPath error:NULL];

        [self fetchAndDisplayEpubInfo:_currentOpenChosenPath];
        
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

#else


- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    if (![dataTask.taskDescription isEqualToString:TASK_DESCRIPTION_LCP_EPUB_DOWNLOAD]) {
        return;
    }
    
    NSString *filename = response.suggestedFilename;
    if (false && // better to name file to match LCPL
        filename.length > 0) {

        NSString *folderPath = [_currentLCPLicensePath stringByDeletingLastPathComponent];
        _currentOpenChosenPath = [folderPath stringByAppendingPathComponent:filename];
//       _currentOpenChosenPath = [NSString stringWithFormat:@"%@%@%@", _currentLCPLicensePath, @"_", filename];
    } else {
        _currentOpenChosenPath = [NSString stringWithFormat:@"%@%@", _currentLCPLicensePath, @".epub"];
    }
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:_currentOpenChosenPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:_currentOpenChosenPath error:NULL];
    }
    
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)task didReceiveData:(NSData *)data
{
    if (![task.taskDescription isEqualToString:TASK_DESCRIPTION_LCP_EPUB_DOWNLOAD]) {
        return;
    }
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:_currentOpenChosenPath]) {
        [data writeToFile:_currentOpenChosenPath atomically:YES];
    } else {
        // TODO: keep handle alive to avoid lots of open/close
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:_currentOpenChosenPath];
        [fileHandle seekToEndOfFile];
        [fileHandle writeData:data];
        [fileHandle closeFile];
    }
    
    float progress = -1;
    float received = task.countOfBytesReceived;
    float expected = task.countOfBytesExpectedToReceive;
    if (expected > 0) {
        progress = received / expected;
    }
    
    
    NSLog(@"%@", [NSString stringWithFormat:@"LCP EPUB acquisition progress: %f percent [%@]=> [%@]", progress * 100.0, _currentLCPLicensePath, _currentOpenChosenPath]);
}

- (void)abortModal:(NSObject*)nope {
    [NSApp abortModal];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if (![task.taskDescription isEqualToString:TASK_DESCRIPTION_LCP_EPUB_DOWNLOAD]) {
        return;
    }
    
    NSInteger code = [(NSHTTPURLResponse *)task.response statusCode];
    
    if (error) {
        
        NSLog(@"%@", [NSString stringWithFormat:@"LCP EPUB acquisition error [%@]=> [%@] (%li)", _currentLCPLicensePath, _currentOpenChosenPath, code]);
        
        [self performSelectorOnMainThread:@selector(abortModal:) withObject:nil waitUntilDone:NO];

        dispatch_async(dispatch_get_main_queue(), ^{
            
            [_epubApi presentAlertWithTitle:@"LCP EPUB acquisition failed" message:@"%@ (%d)(%li) [%@]=> [%@]", error.domain, error.code, code, _currentLCPLicensePath, _currentOpenChosenPath];
            
            _currentLCPLicensePath = nil;
            _currentOpenChosenPath = nil;
            
        });
    } else if (code < 200 || code >= 300) {
        
        NSLog(@"%@", [NSString stringWithFormat:@"LCP EPUB acquisition error [%@]=> [%@] (%li)", _currentLCPLicensePath, _currentOpenChosenPath, code]);
        
        [self performSelectorOnMainThread:@selector(abortModal:) withObject:nil waitUntilDone:NO];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [_epubApi presentAlertWithTitle:@"LCP EPUB acquisition failed" message:@"(%li) [%@]=> [%@]", code, _currentLCPLicensePath, _currentOpenChosenPath];
            
            _currentLCPLicensePath = nil;
            _currentOpenChosenPath = nil;
            
        });
    } else {
        
        NSLog(@"%@", [NSString stringWithFormat:@"LCP EPUB acquisition end [%@]=> [%@] (%li)", _currentLCPLicensePath, _currentOpenChosenPath, code]);

        [self performSelectorOnMainThread:@selector(abortModal:) withObject:nil waitUntilDone:NO];

        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSString *licenseContents = [NSString stringWithContentsOfFile:_currentLCPLicensePath encoding:NSUTF8StringEncoding error:NULL];
            
            [[RDLCPService sharedService] injectLicense:_currentOpenChosenPath licenseJSON:licenseContents];
            
            NSString *title = @"LCP EPUB acquisition finished";
            
            NSString *message = [NSString stringWithFormat:@"EPUB: [%@] => [%@]", _currentLCPLicensePath, _currentOpenChosenPath];
            
            [_epubApi presentAlertWithTitle:title message:message];
            
            _currentLCPLicensePath = nil;
            
            [self fetchAndDisplayEpubInfo:_currentOpenChosenPath];
            
            [self openDocumentWithPath:_currentOpenChosenPath];
        });
    }
}

#endif //ENABLE_NET_PROVIDER_ACQUISITION


- (void)launchStatusDocumentProcessing:(LCPLicense*)lcpLicense
{
    if (_statusDocumentProcessing != nil) {
        [_statusDocumentProcessing cancel];
        _statusDocumentProcessing = nil;
    }
    
    LCPStatusDocumentProcessing_DeviceIdManager* deviceIdManager = [[LCPStatusDocumentProcessing_DeviceIdManager alloc] init_:@"APPLE DEVICE"];
    
    _statusDocumentProcessing = [[LCPStatusDocumentProcessing alloc] init_:[RDLCPService sharedService] epubPath:_currentOpenChosenPath license:lcpLicense deviceIdManager:deviceIdManager];
    
    [_statusDocumentProcessing start:self];
    
if (_alertStatusDocumentProcessing != nil) {
    
    [self performSelectorOnMainThread:@selector(abortModal:) withObject:nil waitUntilDone:NO];
    
    //        [_alertStatusDocumentProcessing.window orderOut:self];
    //        [_alertStatusDocumentProcessing.window close];
    
}
    
    NSString *title = @"LCP LSD processing ...";
    NSString *message = [NSString stringWithFormat:@"EPUB: [%@]", _currentOpenChosenPath];
    //_alertStatusDocumentProcessing = [_epubApi presentAlertWithTitle:title message:message];
    
    _alertStatusDocumentProcessing = [[NSAlert alloc] init];
    [_alertStatusDocumentProcessing setMessageText:title];
    [_alertStatusDocumentProcessing setInformativeText:message];
    
    [_alertStatusDocumentProcessing addButtonWithTitle:@"CLOSE"];
    // [alert addButtonWithTitle:@"SECOND"];
//    
//    [_alertStatusDocumentProcessing beginWithCompletionHandler:^(NSInteger result) {
//       
//    }];
    switch ([_alertStatusDocumentProcessing runModal]) {
        case NSAlertFirstButtonReturn: {
            // CANCEL
            
            if (_statusDocumentProcessing != nil) {
                [_statusDocumentProcessing cancel];
                _statusDocumentProcessing = nil;
            }
            
            break;
        }
        case NSAlertSecondButtonReturn: {
            // SECOND
            break;
        }
        default:
            break;
    }
}

- (void)onStatusDocumentProcessingComplete:(LCPStatusDocumentProcessing*)lsd
{
    if (_statusDocumentProcessing == nil) {
        return;
    }
    _statusDocumentProcessing = nil;
    
    if ([lsd wasCancelled]) {
        return;
    }
    
    [self performSelectorOnMainThread:@selector(onStatusDocumentProcessingComplete_:) withObject:lsd waitUntilDone:NO];
//    
//    dispatch_async(dispatch_get_main_queue(), ^{
//        
//    });
}

- (void)onStatusDocumentProcessingComplete_:(LCPStatusDocumentProcessing*)lsd
{
    if (_alertStatusDocumentProcessing != nil) {
        
        [self performSelectorOnMainThread:@selector(abortModal:) withObject:nil waitUntilDone:NO];
//        [NSApp abortModal];
        
//        [_alertStatusDocumentProcessing.window orderOut:self];
//        [_alertStatusDocumentProcessing.window close];
        
        _alertStatusDocumentProcessing = nil;
    }
    
    // Note that when the license is updated (injected) inside the EPUB archive,
    // the LCPL file has a different canonical form, and therefore the user passphrase
    // is asked again (even though it probably is exactly the same).
    // This is because the passphrase is cached in secure storage based on unique keys
    // for each LCPL file, based on their canonical form (serialised JSON syntax).
    if (![lsd isInitialized] || // e.g. LSD server network timeout
        [lsd hasLicenseUpdatePending]) {
        
        [self performSelectorOnMainThread:@selector(openDocumentWithPath:) withObject:_currentOpenChosenPath waitUntilDone:NO];
        
        return;
    }
    
    
    dispatch_async(dispatch_get_main_queue(), ^{
    
    // The renew + return LSD interactions are invoked here for demonstration purposes only.
    // A real-word app would probably expose the return link in a very different fashion,
    // and may even not necessarily expose the return / renew interactions at the app level (to the end-user),
    // instead: via an intermediary online service / web page, controlled by the content provider.
    
    [self checkLink_RENEW:lsd doneCallback_checkLink_RENEW:^(bool done_checkLink_RENEW){
        
        if (done_checkLink_RENEW) {
            [self performSelectorOnMainThread:@selector(openDocumentWithPath:) withObject:_currentOpenChosenPath waitUntilDone:NO];
            
            return;
        }
        
        [self checkLink_RETURN:lsd doneCallback_checkLink_RETURN:^(bool done_checkLink_RETURN){
            
            [self performSelectorOnMainThread:@selector(openDocumentWithPath:) withObject:_currentOpenChosenPath waitUntilDone:NO];
        }];
    }];
        
    });
    
    
    //        dispatch_async(dispatch_get_main_queue(), ^{
    //    [self openDocumentWithPath:_currentOpenChosenPath];
    //        });
    //[self openDocumentWithCurrentPath];
}

-(void)checkLink_RENEW:(LCPStatusDocumentProcessing*)lsd doneCallback_checkLink_RENEW:(DoneCallback)doneCallback_checkLink_RENEW //void(^)(bool)
{
    if (![lsd isActive]) {
        doneCallback_checkLink_RENEW(false);
        return;
    }
    
    if (![lsd hasRenewLink]) {
        doneCallback_checkLink_RENEW(false);
        return;
    }
    
    
    NSString *title = @"LSD renew?";
    
    NSString *message = @"Renew LCP license?";
    
    //[_epubApi presentAlertWithTitle:title message:message];
    
    NSAlert *renewAlert = [[NSAlert alloc] init];
    [renewAlert setMessageText:title];
    [renewAlert setInformativeText:message];
    
    [renewAlert addButtonWithTitle:@"Yes"];
    [renewAlert addButtonWithTitle:@"No"];
    
    //    [renewAlert beginWithCompletionHandler:^(NSInteger result) {
    //
    //    }];
    switch ([renewAlert runModal]) {
        case NSAlertFirstButtonReturn: {
            // Yes
            [lsd doRenew:doneCallback_checkLink_RENEW];
            break;
        }
        case NSAlertSecondButtonReturn: {
            // No
            doneCallback_checkLink_RENEW(false);
            break;
        }
        default:
            break;
    }
}

-(void)checkLink_RETURN:(LCPStatusDocumentProcessing*)lsd doneCallback_checkLink_RETURN:(DoneCallback)doneCallback_checkLink_RETURN //void(^)(bool)
{
    if (![lsd isActive]) {
        doneCallback_checkLink_RETURN(false);
        return;
    }
    
    if (![lsd hasReturnLink]) {
        doneCallback_checkLink_RETURN(false);
        return;
    }
    
    NSString *title = @"LSD return?";
    
    NSString *message = @"Return LCP license?";
    
    //[_epubApi presentAlertWithTitle:title message:message];
    
    NSAlert *renewAlert = [[NSAlert alloc] init];
    [renewAlert setMessageText:title];
    [renewAlert setInformativeText:message];
    
    [renewAlert addButtonWithTitle:@"Yes"];
    [renewAlert addButtonWithTitle:@"No"];
    
    //    [renewAlert beginWithCompletionHandler:^(NSInteger result) {
    //
    //    }];
    switch ([renewAlert runModal]) {
        case NSAlertFirstButtonReturn: {
            // Yes
            [lsd doReturn:doneCallback_checkLink_RETURN];
            break;
        }
        case NSAlertSecondButtonReturn: {
            // No
            doneCallback_checkLink_RETURN(false);
            break;
        }
        default:
            break;
    }
}


@end
