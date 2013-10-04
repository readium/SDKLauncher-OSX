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

#import "LOXMediaOverlayController.h"
#import "LOXWebViewController.h"
#import "LOXAppDelegate.h"
#import "LOXPackage.h"
//#import <ePub3/package.h>

@interface LOXMediaOverlayController ()
- (void)updateIU;
@end

@implementation LOXMediaOverlayController {
    NSNumber *_timeScrobbler;
}

- (NSNumber*) timeScrobbler
{
    NSLog(@"GET timeScrobbler: %lf", [_timeScrobbler doubleValue]);

    return _timeScrobbler;
}

- (void) setTimeScrobbler:(NSNumber*)timeScrub
{
    NSLog(@"SET timeScrobbler: %lf", [timeScrub doubleValue]);

    if ( _timeScrobbler && [timeScrub isEqualToNumber:_timeScrobbler] )
        return;

    if ( _timeScrobbler )
        [_timeScrobbler release];

    _timeScrobbler = [timeScrub retain];

    if (self.webViewController == nil)
    {
        return;
    }

    ePub3::PackagePtr package = [[self.webViewController loxPackage] sdkPackage];
    if (package == nullptr)
    {
        return;
    }

    ePub3::MediaOverlaysSmilModelPtr mo = package->MediaOverlaysSmilModel();
    if (mo == nullptr)
    {
        return;
    }

    uint32_t total = mo->TotalClipDurationMilliseconds();
    uint32_t timeMs = (uint32_t)(total * ([_timeScrobbler doubleValue] / 100.0));

    NSLog(@"=== TIME SCRUB: %ldms / %ldms", (long) timeMs, (long) total);

    const ePub3::SMILData::Parallel* par = mo->ParallelAt(timeMs);
    if (par == nullptr)
    {
        return;
    }

    if (par->Text() == nullptr)
    {
        return;
    }

    const ePub3::string & smilSrc = par->SmilData()->ManifestItem()->Href();

    std::string textSrc("");
    textSrc.append(par->Text()->SrcFile().c_str());
    if (!par->Text()->SrcFragmentId().empty())
    {
        textSrc.append("#");
        textSrc.append(par->Text()->SrcFragmentId().c_str());
    }

    //reader.openContentUrl(_smilIterator.currentPar.text.src, _smilIterator.smil.href, self);
    [self.webViewController openContentUrl:[NSString stringWithUTF8String: textSrc.c_str()] fromSourceFileUrl:[NSString stringWithUTF8String: smilSrc.c_str()]];
}

-(void) awakeFromNib
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onPageChanged:)
                                                 name:LOXPageChangedEvent
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onMediaOverlayStatusChanged:)
                                                 name:LOXMediaOverlayStatusChangedEvent
                                               object:nil];

    [self.playIndicator setHidden:YES];

    [self updateIU];

    [self setTimeScrobbler:[NSNumber numberWithDouble:0]];
}

- (void)onPageChanged:(id)onPageChanged
{
    [self updateIU];
}

-(void)updateIU
{
    [self.toggleMediaOverlayButton setEnabled: self.webViewController.isMediaOverlayAvailable];
}

- (IBAction)onToggleMediaOverlayClick:(id)sender
{

    [self.webViewController toggleMediaOverlay];

}

- (IBAction)onNextMediaOverlayClick:(id)sender
{
    
    [self.webViewController nextMediaOverlay];
    
}

- (IBAction)onPreviousMediaOverlayClick:(id)sender
{

    [self.webViewController previousMediaOverlay];

}
- (IBAction)onEscapeMediaOverlayClick:(id)sender
{

    [self.webViewController escapeMediaOverlay];

}

-(void)onMediaOverlayStatusChanged:(NSNotification*) notification
{
    NSDictionary *dict = [notification userInfo];
    NSNumber* isPlaying = dict[@"isPlaying"];
    [self.playIndicator setHidden: ![isPlaying boolValue]];
}


@end