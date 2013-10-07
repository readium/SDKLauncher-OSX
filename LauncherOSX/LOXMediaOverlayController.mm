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

#include "media-overlays_smil_data.h"
#include "media-overlays_smil_model.h"

#import <ePub3/media-overlays_smil_utils.h>

@interface LOXMediaOverlayController ()
- (void)updateIU;
@end

@implementation LOXMediaOverlayController
{
    NSNumber *_timeScrobbler;
    //bool skipTimeScrobblerUpdates;
    //bool skipTimeScrobbler;
}

- (IBAction)timeScrobblerValueChanged:(id)sender {
    NSEvent *event = [[NSApplication sharedApplication] currentEvent];
    BOOL startingDrag = event.type == NSLeftMouseDown || event.type == NSKeyUp;
    BOOL endingDrag = event.type == NSLeftMouseUp || event.type == NSKeyDown;
    BOOL dragging = event.type == NSLeftMouseDragged;

    NSAssert(startingDrag || endingDrag || dragging, @"unexpected event type caused slider change: %@", event);

    if (startingDrag) {
        //NSLog(@"slider value started changing");
     //   skipTimeScrobblerUpdates = true;
    }

    //NSLog(@"slider value: %f", [sender doubleValue]);
    //skipTimeScrobblerUpdates = true;

    if (endingDrag) {
        //NSLog(@"slider value stopped changing");
      //  skipTimeScrobblerUpdates = false;

        [self updateView];
    }
}

- (NSNumber *)timeScrobbler
{
    //NSLog(@"GET timeScrobbler: %lf", [_timeScrobbler doubleValue]);

    return _timeScrobbler;
}

- (void)setTimeScrobbler:(NSNumber *)timeScrub
{
    //NSLog(@"SET timeScrobbler: %lf", [timeScrub doubleValue]);

    if (_timeScrobbler && [timeScrub isEqualToNumber:_timeScrobbler])
        return;

    if (_timeScrobbler)
        [_timeScrobbler release];

    _timeScrobbler = [timeScrub retain];
//
//    if (skipTimeScrobbler)
//    {
//        skipTimeScrobbler = false;
//        return;
//    }

//    if (skipTimeScrobblerUpdates)
//    {
//        return;
//    }

    //[self updateView];
}

-(void) updateView
{
    //NSLog(@"updateView");

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

    uint32_t smilIndex = 0;
    uint32_t parIndex = 0;
    uint32_t milliseconds = 0;
    const ePub3::SMILData::Parallel *par = nullptr;
    ePub3::SMILDataPtr smilData = nullptr;
    mo->PercentToPosition([_timeScrobbler doubleValue], smilData, smilIndex, par, parIndex, milliseconds);

    if (par == nullptr || par->Text() == nullptr || smilData == nullptr)
    {
        return;
    }

    const ePub3::string & smilSrc = smilData->SmilManifestItem()->Href(); //par->SmilData()

    std::string textSrc("");
    textSrc.append(par->Text()->SrcFile().c_str());
    if (!par->Text()->SrcFragmentId().empty())
    {
        textSrc.append("#");
        textSrc.append(par->Text()->SrcFragmentId().c_str());
    }
    //NSLog(@"*** PAR TEXT: %s", textSrc.c_str());

    double offsetS = milliseconds / 1000.0;
    [self.webViewController mediaOverlaysOpenContentUrl:[NSString stringWithUTF8String:textSrc.c_str()] fromSourceFileUrl:[NSString stringWithUTF8String:smilSrc.c_str()] forward: offsetS];
}

- (void)awakeFromNib
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

    //skipTimeScrobbler = false;
    //skipTimeScrobblerUpdates = false;

    [self setTimeScrobbler:[NSNumber numberWithDouble:0]];
}

- (void)onPageChanged:(id)onPageChanged
{
    [self updateIU];
}

- (void)updateIU
{
    [self.toggleMediaOverlayButton setEnabled:self.webViewController.isMediaOverlayAvailable];
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

- (void)onMediaOverlayStatusChanged:(NSNotification *)notification
{
    NSDictionary *dict = [notification userInfo];
    if (dict == nil)
    {
        return;
    }
    NSNumber *isPlaying = [dict objectForKey:@"isPlaying"];//dict[@"isPlaying"];
    if (isPlaying != nil)
    {
        [self.playIndicator setHidden:![isPlaying boolValue]];
    }

    NSNumber *playPosition = [dict objectForKey:@"playPosition"];
    NSNumber *parIndex = [dict objectForKey:@"parIndex"];
    NSNumber *smilIndex = [dict objectForKey:@"smilIndex"];
    if (playPosition != nil && parIndex != nil && smilIndex != nil)
    {
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

        uint32_t smilIndex_ = (uint32_t)floor([smilIndex doubleValue]);
        uint32_t parIndex_ = (uint32_t)floor([parIndex doubleValue]);
        uint32_t playPositionMS = (uint32_t)floor([playPosition doubleValue] * 1000.0);

        double percent = mo->PositionToPercent(smilIndex_, parIndex_, playPositionMS);

        if (percent < 0)
        {
            return;
        }

//        if (skipTimeScrobblerUpdates)
//        {
//            return;
//        }

//        skipTimeScrobbler = true;
        [self setTimeScrobbler: [NSNumber numberWithDouble:percent]];
        //[self.timeScrobbler initWithDouble: playPosition];
    }
}


@end