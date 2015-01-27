//  LauncherOSX
//
//  Created by Boris Schneiderman.
//  Modified by Daniel Weck
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

#import <AppKit/AppKit.h>

#import "LOXMediaOverlayController.h"
#import "LOXWebViewController.h"
#import "LOXAppDelegate.h"
#import "LOXPackage.h"
#import "LOXPreferencesController.h"
#import "LOXPreferences.h"

#import <ePub3/media-overlays_smil_data.h>
#import <ePub3/media-overlays_smil_model.h>
#import <ePub3/media-overlays_smil_utils.h>

@interface LOXMediaOverlayController ()
- (void)updateIU;
@end

@implementation LOXMediaOverlayController
{
    NSNumber *_timeScrobbler;
    //bool skipTimeScrobblerUpdates;
    //bool skipTimeScrobbler;

    NSSpeechSynthesizer *_speech;
    bool _skipTTSEnd;
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

    _timeScrobbler = timeScrub;
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

    std::shared_ptr<ePub3::MediaOverlaysSmilModel> mo = package->MediaOverlaysSmilModel();
    if (mo == nullptr)
    {
        return;
    }

    uint32_t smilIndex = 0;
    uint32_t parIndex = 0;
    uint32_t milliseconds = 0;
    std::shared_ptr<const const ePub3::SMILData::Parallel> par = nullptr;
    std::shared_ptr<ePub3::SMILData> smilData = nullptr;
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

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onMediaOverlayTTSSpeak:)
                                                 name:LOXMediaOverlayTTSSpeakEvent
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onMediaOverlayTTSStop:)
                                                 name:LOXMediaOverlayTTSStopEvent
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

- (id)init
{
    self = [super init];
    if (self)
    {
        _skipTTSEnd = false;

        _speech = [[NSSpeechSynthesizer alloc] init];
        [_speech setDelegate:self];

#if __MAC_OS_X_VERSION_MIN_REQUIRED >= __MAC_10_5
        [_speech setRate: 200]; //180-220 WPM
        [_speech setVolume: 1.0];
#endif

        //NSString *voice = @"Bruce";
        //NSSpeechSynthesizer *speech = [[NSSpeechSynthesizer alloc] initWithVoice: [NSString stringWithFormat:@"com.apple.speech.synthesis.voice.%@", voice]];

        //[_speech release];
    }
    return self;
}

-(void)updateSettings:(LOXPreferences *)preferences
{

#if __MAC_OS_X_VERSION_MIN_REQUIRED >= __MAC_10_5


    NSNumber * vol = preferences.mediaOverlaysVolume;
    double vol_ = [vol doubleValue] / 100.0;
    //NSLog(@"SPEECH SETTING VOLUME: %f", vol_);
    [_speech setVolume: vol_];

    NSNumber * rate = [preferences mediaOverlaysRate];
    double rate_ = 200 * [rate doubleValue];

    //NSLog(@"SPEECH SETTING RATE: %f", rate_);
    [_speech setRate: rate_];

//    double currentRate = [_speech rate];
//    if (currentRate != rate_)
//    {
//        bool wasSpeaking = [_speech isSpeaking];
//
//        if (wasSpeaking)
//        {
//            NSLog(@"SPEECH SETTING PAUSE");
//            [_speech pauseSpeakingAtBoundary: NSSpeechWordBoundary];
//
//            //        while([_speech isSpeaking]) //[NSSpeechSynthesizer isAnyApplicationSpeaking]
//            //        {
//            //            NSLog(@"SPEECH SETTING WAIT...");
//            //            usleep(200);
//            //        }
//        }
//
//        //NSLog(@"SPEECH SETTING RATE: %f", rate_);
//        [_speech setRate: rate_];
//
//        if (wasSpeaking)
//        {
//            NSLog(@"SPEECH SETTING RESUME");
//            [_speech continueSpeaking];
//        }
//    }

#endif
}

/*
https://developer.apple.com/library/mac/documentation/userexperience/conceptual/SpeechSynthesisProgrammingGuide/Introduction/Introduction.html
*/
- (void)onMediaOverlayTTSSpeak:(NSNotification *)notification
{
    NSDictionary *dict = [notification userInfo];
    if (dict == nil)
    {
        return;
    }

//    if (self.webViewController != nil)
//    {
//        //[self updateSettings: [[[self.webViewController appDelegate] preferencesController] preferences]];
//        [self updateSettings: [self.webViewController appDelegate].getPreferences];
//    }

    NSString *tts = [dict objectForKey:@"tts"];//dict[@"tts"];
    if (tts != nil)
    {
        NSError* error = [[NSError alloc]init];
        NSDictionary* dic = [_speech objectForProperty:NSSpeechStatusProperty error: &error];
        //NSSpeechStatusOutputPaused  NSSpeechStatusOutputBusy

        NSNumber* yes = [NSNumber numberWithBool:YES];

        if ([_speech isSpeaking] || [[dic valueForKey:NSSpeechStatusOutputPaused] isEqual:yes] || [[dic valueForKey:NSSpeechStatusOutputBusy] isEqual:yes])
        {
            _skipTTSEnd = true;

//            NSLog(@"SPEECH STOP");
            [_speech stopSpeaking];

//        while([_speech isSpeaking]) //[NSSpeechSynthesizer isAnyApplicationSpeaking]
//        {
////                NSLog(@"SPEECH WAIT...");
//            usleep( 250 );
//        }
        }

//        NSLog(@"SPEECH SPEAK: %@", tts);
        [_speech startSpeakingString: tts];
    }
    else
    {
//        NSLog(@"SPEECH CONTINUE");
        [_speech continueSpeaking];
    }
}
- (void)speechSynthesizer:(NSSpeechSynthesizer *)sender didFinishSpeaking:(BOOL)finishedSpeaking
{
    //NSLog(@"SPEECH ENDED");

    if (_skipTTSEnd)
    {
        //NSLog(@"SPEECH END SKIPPED");

        _skipTTSEnd = false;
        return;
    }
    if (self.webViewController == nil)
    {
        return;
    }

    [self.webViewController ttsEndedMediaOverlay];
}

- (void)onMediaOverlayTTSStop:(NSNotification *)notification
{
//    NSLog(@"SPEECH PAUSE");
    [_speech pauseSpeakingAtBoundary: NSSpeechImmediateBoundary];
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

        std::shared_ptr<ePub3::MediaOverlaysSmilModel> mo = package->MediaOverlaysSmilModel();
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