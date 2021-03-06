//
//  DialogEvent.h
//  hanokam
//
//  Created by spotco on 11/08/2015.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import <Foundation/Foundation.h>
@class GameEngineScene;
@class BGCharacterBase;

#define DIALOGTEXT_EMPH @"emph"

@interface DialogEvent : NSObject
+(DialogEvent*)cons_text:(NSString*)text speaker:(BGCharacterBase*)speaker;
-(NSString*)get_text;
-(BGCharacterBase*)get_speaker;
-(void)i_update:(GameEngineScene*)g;
-(BOOL)is_animation_finished;
@end
