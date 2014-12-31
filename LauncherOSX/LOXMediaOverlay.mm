//
// Created by Boris Schneiderman on 2013-08-20.
// Modified by Daniel Weck
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

#import "LOXMediaOverlay.h"
#import "LOXSmilModel.h"

#import <ePub3/package.h>
#import <ePub3/media-overlays_smil_data.h>
#import <ePub3/media-overlays_smil_model.h>
#import <ePub3/media-overlays_smil_utils.h>



@interface LOXMediaOverlay ()
//- (NSString *)getProperty:(NSString *)name fromPropertyHolder:(std::shared_ptr<ePub3::PropertyHolder>)sdkPropertyHolder;
- (void)saveProperty:(NSString *)valueName toDictionary:(NSMutableDictionary *)dict;
@end

@implementation LOXMediaOverlay {

    NSMutableArray *_smilModels;

    NSMutableArray *_skippables;
    NSMutableArray *_escapables;
}

@synthesize smilModels = _smilModels;

@synthesize skippables = _skippables;
@synthesize escapables = _escapables;


+ (NSString *) defaultEscapables
{
    NSMutableArray* arr = [NSMutableArray array];
    
    auto count = ePub3::MediaOverlaysSmilModel::GetEscapablesCount();
    for (int i = 0; i < count; i++)
    {
        auto str = ePub3::MediaOverlaysSmilModel::GetEscapable(i);
        [arr addObject:[NSString stringWithUTF8String: str.c_str()]];
    }
    
    return [arr componentsJoinedByString:@", "];
}

+ (NSString *) defaultSkippables
{
    NSMutableArray* arr = [NSMutableArray array];
    
    auto count = ePub3::MediaOverlaysSmilModel::GetSkippablesCount();
    for (int i = 0; i < count; i++)
    {
        auto str = ePub3::MediaOverlaysSmilModel::GetSkippable(i);
        [arr addObject:[NSString stringWithUTF8String: str.c_str()]];
    }
    
    return [arr componentsJoinedByString:@", "];
}

- (id)initWithSdkPackage:(ePub3::PackagePtr)sdkPackage
{
    self = [super init];

    if(self) {

        auto ePubSmilModel = sdkPackage->MediaOverlaysSmilModel();

        auto narrator = ePubSmilModel->Narrator(); //sdkPackage->MediaOverlays_Narrator();
        self.narrator = [NSString stringWithUTF8String: narrator.c_str()];
        //NSLog(@"=== NARRATOR: [%s]", [self.narrator UTF8String]);

        auto activeClass = ePubSmilModel->ActiveClass(); //sdkPackage->MediaOverlays_ActiveClass();
        self.activeClass = [NSString stringWithUTF8String: activeClass.c_str()];
        //NSLog(@"=== ACTIVE-CLASS: [%s]", [self.activeClass UTF8String]);

        auto playbackActiveClass = ePubSmilModel->PlaybackActiveClass(); //sdkPackage->MediaOverlays_PlaybackActiveClass();
        self.playbackActiveClass = [NSString stringWithUTF8String: playbackActiveClass.c_str()];
        //NSLog(@"=== PLAYBACK-ACTIVE-CLASS: [%s]", [self.playbackActiveClass UTF8String]);

        self.duration = [NSNumber numberWithDouble: ePubSmilModel->DurationMilliseconds_Metadata() / 1000.0];
        //NSLog(@"=== TOTAL MO DURATION: %ldms", (long) floor([self.duration doubleValue] * 1000.0));

        _smilModels = [NSMutableArray array];


        _skippables = [NSMutableArray array];
        auto count = ePub3::MediaOverlaysSmilModel::GetSkippablesCount();
        for (int i = 0; i < count; i++)
        {
            auto str = ePub3::MediaOverlaysSmilModel::GetSkippable(i);
            [_skippables addObject:[NSString stringWithUTF8String: str.c_str()]];
        }

        _escapables = [NSMutableArray array];
        count = ePub3::MediaOverlaysSmilModel::GetEscapablesCount();
        for (int i = 0; i < count; i++)
        {
            auto str = ePub3::MediaOverlaysSmilModel::GetEscapable(i);
            [_escapables addObject:[NSString stringWithUTF8String: str.c_str()]];
        }


        count = ePubSmilModel->GetSmilCount();
        for (int i = 0; i < count; i++)
        {
            auto smilData = ePubSmilModel->GetSmil(i);

            LOXSmilModel * smil = [[LOXSmilModel alloc] init];

            smil.smilVersion = [NSString stringWithUTF8String: "3.0"];

            smil.duration = [NSNumber numberWithDouble: smilData->DurationMilliseconds_Metadata() / 1000.0];

            auto item = smilData->SmilManifestItem();

            smil.spineItemId = [NSString stringWithUTF8String:smilData->XhtmlSpineItem()->Idref().c_str()];

            smil.id = item == nullptr ? [NSString stringWithUTF8String:""] : [NSString stringWithUTF8String:item->Identifier().c_str()];
            smil.href = item == nullptr ? [NSString stringWithUTF8String:"fake.smil"] : [NSString stringWithUTF8String:item->Href().c_str()];

            //NSLog(@"=== smil.id: [%s]", [smil.id UTF8String]);
            //NSLog(@"=== smil.href: [%s]", [smil.href UTF8String]);

            auto seq = smilData->Body();
            if (seq == nullptr)
            {
                throw std::invalid_argument("Media Overlays SMIL body is null!!?");
            }

            NSMutableDictionary *smilItem = [self parseTree_Sequence: seq.get()];

            [smil addItem:smilItem];

            [_smilModels addObject:smil];
        }
    }

    return self;
}

- (NSMutableDictionary *) parseTree_Text:(const ePub3::SMILData::Text*)node
{
    NSMutableDictionary *smilItem = [NSMutableDictionary dictionary];

    smilItem[@"nodeType"] = [NSString stringWithUTF8String: node->Name().c_str()];

//NSLog(@"=== nodeType: [%s]", [smilItem[@"nodeType"] UTF8String]);


    smilItem[@"srcFile"] = [NSString stringWithUTF8String: node->SrcFile().c_str()];

    std::string str("");
    str.append(node->SrcFile().c_str());
    if (!node->SrcFragmentId().empty())
    {
        smilItem[@"srcFragmentId"] = [NSString stringWithUTF8String: node->SrcFragmentId().c_str()];

        str.append("#");
        str.append(node->SrcFragmentId().c_str());
    }
    else
    {
        smilItem[@"srcFragmentId"] = [NSString stringWithUTF8String:""];
    }

    smilItem[@"src"] = [NSString stringWithUTF8String: str.c_str()];

//    NSMutableArray *children = [NSMutableArray array];
//    smilItem[@"children"] = children;

    return smilItem;
}

- (NSMutableDictionary *) parseTree_Audio:(const ePub3::SMILData::Audio*)node
{
    NSMutableDictionary *smilItem = [NSMutableDictionary dictionary];

    smilItem[@"nodeType"] = [NSString stringWithUTF8String: node->Name().c_str()];

//NSLog(@"=== nodeType: [%s]", [smilItem[@"nodeType"] UTF8String]);

    std::string str("");
    str.append(node->SrcFile().c_str());
//    if (!node->SrcFragmentId().empty())
//    {
//        smilItem[@"srcFragmentId"] = [NSString stringWithUTF8String: node->SrcFragmentId().c_str()];
//        
//        str.append("#");
//        str.append(node->SrcFragmentId().c_str());
//    }
//    else
//    {
//        smilItem[@"srcFragmentId"] = [NSString stringWithUTF8String:""];
//    }

    smilItem[@"src"] = [NSString stringWithUTF8String: str.c_str()];

    smilItem[@"clipBegin"] = [NSNumber numberWithDouble: node->ClipBeginMilliseconds() / 1000.0];
    smilItem[@"clipEnd"] = [NSNumber numberWithDouble: node->ClipEndMilliseconds() / 1000.0];


//    NSMutableArray *children = [NSMutableArray array];
//    smilItem[@"children"] = children;

    return smilItem;
}

- (NSMutableDictionary *) parseTree_Parallel:(ePub3::SMILData::Parallel*)node
{
    NSMutableDictionary *smilItem = [NSMutableDictionary dictionary];

    smilItem[@"nodeType"] = [NSString stringWithUTF8String: node->Name().c_str()];

//NSLog(@"=== nodeType: [%s]", [smilItem[@"nodeType"] UTF8String]);

    smilItem[@"epubtype"] = [NSString stringWithUTF8String: node->Type().c_str()];

    NSMutableArray *children = [NSMutableArray array];

    auto textMedia = node->Text();
    if (textMedia != nullptr && textMedia->IsText())
    {
        NSMutableDictionary *text = [self parseTree_Text: textMedia.get()];
        [children addObject:text];
    }

    auto audioMedia = node->Audio();
    if (audioMedia != nullptr && audioMedia->IsAudio())
    {
        NSMutableDictionary *audio = [self parseTree_Audio: audioMedia.get()];
        [children addObject:audio];
    }

    smilItem[@"children"] = children;

    return smilItem;
}

- (NSMutableDictionary *) parseTree_Sequence:(const ePub3::SMILData::Sequence*)node
{
    NSMutableDictionary *smilItem = [NSMutableDictionary dictionary];

    smilItem[@"nodeType"] = [NSString stringWithUTF8String: node->Name().c_str()];

//NSLog(@"=== nodeType: [%s]", [smilItem[@"nodeType"] UTF8String]);

    std::string str("");
    str.append(node->TextRefFile().c_str());
    if (!node->TextRefFragmentId().empty())
    {
        str.append("#");
        str.append(node->TextRefFragmentId().c_str());
    }

    smilItem[@"textref"] = [NSString stringWithUTF8String: str.c_str()];

    smilItem[@"epubtype"] = [NSString stringWithUTF8String: node->Type().c_str()];

    NSMutableArray *children = [NSMutableArray array];

    auto count = node->GetChildrenCount();
    for (int i = 0; i < count; i++)
    {
        const ePub3::SMILData::TimeContainer *container = node->GetChild(i).get();

        //const ePub3::SMILData::Sequence *seq = dynamic_cast<ePub3::SMILData::Sequence *>(container);
        //if (seq != nullptr)
        //if ([[NSString stringWithUTF8String:container->Name().c_str()] isEqualToString:@"seq"])
        if (container->IsSequence())
        {
            NSMutableDictionary *seqx = [self parseTree_Sequence: (ePub3::SMILData::Sequence *)container];
            [children addObject:seqx];
            continue;
        }

        //const ePub3::SMILData::Parallel *par = dynamic_cast<ePub3::SMILData::Parallel *>(container);
        //if (par != nullptr)
        //if ([[NSString stringWithUTF8String: container->Name().c_str()] isEqualToString:@"par"])
        if (container->IsParallel())
        {
            NSMutableDictionary *parx = [self parseTree_Parallel: (ePub3::SMILData::Parallel *)container];
            [children addObject:parx];
            continue;
        }

        throw std::invalid_argument("WTF?");
    }

    if ([children count] != 0)
    {
        smilItem[@"children"] = children;
    }

    return smilItem;
}

- (NSDictionary *)toDictionary {

    NSMutableDictionary *dict = [NSMutableDictionary dictionary];

    NSMutableArray *smilDictionaries = [NSMutableArray array];
    for(LOXSmilModel *mo in _smilModels) {
        [smilDictionaries addObject:[mo toDictionary]];
    }

    [dict setObject:smilDictionaries forKey:@"smil_models"];

    [dict setObject:self.skippables forKey:@"skippables"];
    [dict setObject:self.escapables forKey:@"escapables"];

    [dict setObject:self.duration forKey:@"duration"];

    [dict setObject:self.narrator forKey:@"narrator"];

    [dict setObject:self.activeClass forKey:@"activeClass"];

    [dict setObject:self.playbackActiveClass forKey:@"playbackActiveClass"];

    return dict;
}

- (void)saveProperty:(NSString *)valueName toDictionary:(NSMutableDictionary*)dict
{
    NSObject* value = [self valueForKey:valueName];
    if(value) {
        [dict setObject:value forKey:valueName];
    }
}

@end