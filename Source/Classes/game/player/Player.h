#import "CCSprite.h"
#import "Common.h"
#import "PolyLib.h"
#import "GameEngineScene.h" 

@class GameEngineScene;
@class PlayerLandParams;
#import "PlayerSharedParams.h"
@class SpriterNode;
@class BasePlayerStateStack;
@class BGCharacterBase;

@interface Player : CCSprite <SATPolyHitOwner>

+(Player*)cons_g:(GameEngineScene*)g;

-(void)i_update:(GameEngineScene*)g;
-(BOOL)is_underwater:(GameEngineScene*)g;
-(HitRect)get_hit_rect;
-(CGPoint)get_center;

-(PlayerState)get_player_state;
-(BasePlayerStateStack*)get_top_state;

//internal State stack methods
-(PlayerSharedParams*)shared_params;
-(float)get_next_update_accel_x_position:(GameEngineScene*)g;
-(float)get_next_update_accel_x_position_delta:(GameEngineScene*)g;
-(void)update_accel_x_position:(GameEngineScene*)g;
-(void)apply_s_pos:(GameEngineScene*)g;
-(void)read_s_pos:(GameEngineScene*)g;

-(void)play_anim:(NSString*)anim repeat:(BOOL)repeat;
-(void)play_anim:(NSString*)anim1 on_finish_anim:(NSString*)anim2;
-(SpriterNode*)img;

-(void)pop_state_stack:(GameEngineScene*)g;
-(void)push_state_stack:(BasePlayerStateStack*)item;

-(BGCharacterBase*)get_player_dialogue_character;

@end
