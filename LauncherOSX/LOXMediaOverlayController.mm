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

    uint32_t total = mo->TotalClipDurationMilliseconds();
    uint32_t timeMs = (uint32_t) (total * ([_timeScrobbler doubleValue] / 100.0));

    //NSLog(@"=== TIME SCRUB: %ldms / %ldms (==%ldms)", (long) timeMs, (long) total, (long) mo->DurationMillisecondsTotal());

    const ePub3::SMILData::Parallel *par = mo->ParallelAt(timeMs);
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
    //NSLog(@"*** PAR TEXT: %s", textSrc.c_str());

    uint32_t smilDataOffset = 0;
    for (std::vector<ePub3::SMILDataPtr>::size_type i = 0; i < mo->GetSmilCount(); i++)
    {
        ePub3::SMILDataPtr smilData = mo->GetSmil(i);
        if (smilData == par->SmilData())
        {
            break;
        }
        smilDataOffset += smilData->TotalClipDurationMilliseconds();
    }

    uint32_t offset = smilDataOffset;
    if (par->ClipOffset(offset))
    {
        //NSLog(@"=== PAR OUTER OFFSET: %ldms", (long) offset);
        offset = timeMs - offset;
    }

    //NSLog(@"=== PAR INNER OFFSET: %ldms", (long) offset);

    double offsetS = offset / 1000.0;
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

        std::vector<ePub3::SMILDataPtr>::size_type j = (std::vector<ePub3::SMILDataPtr>::size_type)floor([smilIndex doubleValue]);
        if (j < 0 && j >= mo->GetSmilCount())
        {
            return;
        }

        uint32_t smilDataOffset = 0;
        for (std::vector<ePub3::SMILDataPtr>::size_type i = 0; i < j; i++)
        {
            ePub3::SMILDataPtr sd = mo->GetSmil(i);
            smilDataOffset += sd->TotalClipDurationMilliseconds();
        }

        uint32_t k = (uint32_t)floor([parIndex doubleValue]);
        if (k < 0)
        {
            return;
        }

        ePub3::SMILDataPtr smilData = mo->GetSmil(j);

        const ePub3::SMILData::Parallel *par = smilData->NthParallel(k);
        if (par == nullptr)
        {
            return;
        }

        uint32_t playPositionMS = (uint32_t)floor([playPosition doubleValue] * 1000.0);

        uint32_t offset = smilDataOffset + playPositionMS;
        if (!par->ClipOffset(offset))
        {
            return;
        }



        uint32_t total = mo->TotalClipDurationMilliseconds();

        double percent = ((double)offset / (double)total) * 100.0;

        //NSLog(@"=== TIME SCRUB [%f%] %ldms / %ldms (==%ldms)", percent, (long) offset, (long) total, (long) mo->DurationMillisecondsTotal());
//
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