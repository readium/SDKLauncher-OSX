//
//  LOXePubSdkApi.m
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

#import "LOXePubSdkApi.h"

#import <ePub3/container.h>
#import <ePub3/nav_table.h>
#include <ePub3/initialization.h>

#include <ePub3/utilities/error_handler.h>

#import "LOXSpineItem.h"
#import "LOXPackage.h"



@interface LOXePubSdkApi ()

- (void)cleanup;

- (void)readPackages;

@end

@implementation LOXePubSdkApi {
    NSMutableArray *_packages;

    ePub3::ContainerPtr _container;

    LOXPackage* _currentPackage;
}

static BOOL m_ignoreRemainingErrors = NO;

bool LauncherErrorHandler(const ePub3::error_details& err)
{
    const char * msg = err.message();
    NSLog(@"%s\n", msg);


    if (err.is_spec_error())
    {
        switch ( err.severity() )
        {
            case ePub3::ViolationSeverity::Critical:
            case ePub3::ViolationSeverity::Major: {

                if (m_ignoreRemainingErrors != YES)
                {
                    NSAlert *alert = [[NSAlert alloc] init];
                    [alert setMessageText:@"EPUB warning:"];
                    [alert setInformativeText:[NSString stringWithUTF8String:msg]];

                    [alert addButtonWithTitle:@"Ignore"];
                    [alert addButtonWithTitle:@"Ignore all"];
                    switch ([alert runModal]) {
                        case NSAlertFirstButtonReturn: {
                            // Dismiss
                            break;
                        }
                        case NSAlertSecondButtonReturn: {
                            // Ignore all
                            m_ignoreRemainingErrors = YES;
                            break;
                        }
                        default:
                            break;
                    }
                }

                break;
            }
            default:
                break;
        }
    }

    return true;
    // never throws an exception
    //return ePub3::DefaultErrorHandler(err);
}

+(void)initialize
{
    ePub3::ErrorHandlerFn launcherErrorHandler = LauncherErrorHandler;
    ePub3::SetErrorHandler(launcherErrorHandler);

    ePub3::InitializeSdk();
    ePub3::PopulateFilterManager();
}

- (id)init
{
    self = [super init];
    
    if(self){

        _packages = [NSMutableArray array];
    }

    return self;
}

- (LOXPackage *)openFile:(NSString *)file
{
    [self cleanup];

     _container = ePub3::Container::OpenContainer([file UTF8String]);

    [self readPackages];

    if([_packages count] > 0) {
        return [_packages objectAtIndex:0];
    }

    return nil;
}

- (void)readPackages
{
    auto packages = _container->Packages();

    for (auto package = packages.begin(); package != packages.end(); ++package) {

        [_packages addObject:[[LOXPackage alloc] initWithSdkPackage:*package]];
    }
}


- (void)dealloc
{
    [self cleanup];
}

- (void)cleanup
{
    m_ignoreRemainingErrors = NO;
    [_packages removeAllObjects];
    _currentPackage = nil;
}

- (BOOL)isValidFile:(NSString *)path
{
    return [self.supportedFileExtensions containsObject:path.pathExtension.lowercaseString];
}

- (BOOL)canOpenFile:(NSString *)path
{
    return [path.pathExtension.lowercaseString isEqual:@"epub"];
}

- (NSArray *)supportedFileExtensions
{
//    NSArray *fileTypesArray = [NSArray arrayWithObjects:@"epub", @"lcpl", nil];
    
    NSArray *fileTypesArray =  @[@"epub", @"lcpl"];
    
//    NSString *strings[2];
//    strings[0] = @"epub";
//    strings[1] = @"lcpl";
//    NSArray *fileTypesArray = [NSArray arrayWithObjects:strings count:2];
    
    return fileTypesArray;
}

- (void)presentAlertWithTitle:(NSString *)title message:(NSString *)message, ... {
    va_list args;
    va_start(args, message);
    message = [[NSString alloc] initWithFormat:message arguments:args];
    va_end(args);
    
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:title];
    [alert setInformativeText:message];
    
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

- (NSString*)presentAlertWithInput:(NSString *)title inputDefaultText:(NSString *)inputDefaultText message:(NSString *)message, ... {
    
    va_list args;
    va_start(args, message);
    message = [[NSString alloc] initWithFormat:message arguments:args];
    va_end(args);
    
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:title];
    [alert setInformativeText:message];
    
    NSTextField *input = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 200, 24)];
    [input setStringValue:inputDefaultText];
    
    [alert setAccessoryView:input];
    
    [alert addButtonWithTitle:@"OK"];
    [alert addButtonWithTitle:@"CANCEL"];

    switch ([alert runModal]) {
        case NSAlertFirstButtonReturn: {
            // OK
            
            [input validateEditing];
            return [input stringValue];

            break;
        }
        case NSAlertSecondButtonReturn: {
            // SECOND
            
            break;
        }
        default:
            break;
    }
    
    return nil;
}

- (BOOL)fileExistsAtPath:(NSString *)relativePath {
    return _container->FileExistsAtPath([relativePath UTF8String]);
}

- (NSString *)contentsOfFileAtPath:(NSString *)relativePath encoding:(NSStringEncoding)encoding {
    if (![self fileExistsAtPath:relativePath])
        return nil;
    
    std::unique_ptr<ePub3::ByteStream> stream = _container->ReadStreamAtPath([relativePath UTF8String]);
    if (stream == nullptr)
        return nil;
    
    void *buffer = nullptr;
    size_t length = stream->ReadAllBytes(&buffer);
    std::string nativeContent((char *)buffer, length);
    free (buffer);
    
    return [NSString stringWithCString:nativeContent.c_str() encoding:encoding];
}

@end
