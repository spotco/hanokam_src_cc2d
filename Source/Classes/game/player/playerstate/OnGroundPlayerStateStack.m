//
//  OnGroundPlayerStateStack.m
//  hanokam
//
//  Created by spotco on 06/06/2015.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "OnGroundPlayerStateStack.h"
#import "PlayerLandParams.h"
#import "DivePlayerStateStack.h"
#import "GameMain.h"
#import "GEventDispatcher.h"
#import "BGVillage.h"
#import "BGCharacterBase.h"
#import "InDialoguePlayerStateStack.h"

@implementation OnGroundPlayerStateStack {
	PlayerLandParams *_land_params;
}

+(OnGroundPlayerStateStack*)cons:(GameEngineScene*)g {
	return [[[OnGroundPlayerStateStack alloc] init] cons:g];
}

-(OnGroundPlayerStateStack*)cons:(GameEngineScene*)g {
	_land_params = [[PlayerLandParams alloc] init];
	g.player.rotation = 0;
	[g.player read_s_pos:g];
	_land_params._current_mode = PlayerLandMode_OnDock;
	return self;
}

-(void)i_update:(GameEngineScene *)g {
    g.player.shared_params._reset_to_center = (!TARGET_IPHONE_SIMULATOR) ? YES : NO;
	switch(_land_params._current_mode) {
		case PlayerLandMode_OnDock:;
			[g set_zoom:drpt(g.get_zoom,1,1/20.0)];
			
			[g set_camera_height:drpt(g.get_current_camera_center_y,150,1/20.0)];
			if (g.get_control_manager.is_touch_down) {
				[g.player play_anim:@"Prep Dive" repeat:NO];
				_land_params._prep_dive_hold_ct += dt_scale_get();
				[g.get_event_dispatcher push_event:[[GEvent cons_context:g type:GEventType_PlayerChargePct] set_float_value:_land_params._prep_dive_hold_ct/_land_params.PREP_DIVE_HOLD_TIME]];
				
				
				if (_land_params._prep_dive_hold_ct > _land_params.PREP_DIVE_HOLD_TIME) {
					_land_params._current_mode = PlayerLandMode_LandToWater;
					_land_params._vel = ccp(0,10 * dt_scale_get());
				}
            } else if (g.get_control_manager.is_proc_tap) {
				CGPoint tapPos = g.get_control_manager.get_proc_tap;
				CGPoint world_tap_pos = [g.get_anchor convertToNodeSpace:tapPos];
				for (BGCharacterBase *itr in g.get_bg_village.get_villagers) {
					if (hitrect_contains_point([itr get_hit_rect:g], world_tap_pos)) {
						[g.get_control_manager clear_proc_tap]; //consume tap
                        [g.player push_state_stack:[InDialoguePlayerStateStack cons:g with_character:itr]];
						return;
					}
				}
			
#if TARGET_IPHONE_SIMULATOR
                CGFloat newXPos;
                if (tapPos.x > g.player.position.x) {
                    newXPos = g.player.position.x + 10;
                } else {
                    newXPos = g.player.position.x - 10;
                }
                g.player.position = ccp(newXPos, g.player.position.y);
                [g.player read_s_pos:g];
#endif
            } else {
				if (_land_params._prep_dive_hold_ct > 0) {
					[g.get_event_dispatcher push_event:[GEvent cons_context:g type:GEventType_PlayerChargePct]];
					_land_params._prep_dive_hold_ct = 0;
				}
				float vx = [g.player get_next_update_accel_x_position_delta:g];
				if (ABS(vx) > _land_params.MOVE_CUTOFF_VAL
					|| ABS(g.player.shared_params._s_pos.x-g.player.shared_params._calc_accel_x_pos) > 1 //not recentered yet to _calc_accel_x_pos
					) {
					_land_params._move_hold_ct += dt_scale_get();
					if (_land_params._move_hold_ct > _land_params.MOVE_HOLD_TIME) {
						[g.player update_accel_x_position:g];
						[g.player play_anim:@"Walk" repeat:YES];
						if (vx > 0) {
							g.player.img.scaleX = -ABS(g.player.img.scaleX);
						} else {
							g.player.img.scaleX = ABS(g.player.img.scaleX);
						}
					} else {
						[g.player play_anim:@"Idle" repeat:YES];
					}
				} else {
					_land_params._move_hold_ct = 0;
					[g.player play_anim:@"Idle" repeat:YES];
				}
				g.player.position = ccp(g.player.position.x,g.DOCK_HEIGHT);
				[g.player read_s_pos:g];
			}
		break;
		case PlayerLandMode_LandToWater:;
			[g set_zoom:drpt(g.get_zoom,1.25,1/20.0)];
			[g set_camera_height:drpt(g.get_current_camera_center_y,g.player.position.y,1/10.0)];
			
			[g.player read_s_pos:g];
			
			CGPoint last_s_pos = g.player.shared_params._s_pos;
			[g.player update_accel_x_position:g];
			_land_params._vel = ccp(0,_land_params._vel.y - 0.4 * dt_scale_get() * dt_scale_get());
			g.player.shared_params._s_pos = CGPointAdd(g.player.shared_params._s_pos, _land_params._vel);
			
			float tar_rotation = vec_ang_deg_lim180(vec_cons(g.player.shared_params._s_pos.x - last_s_pos.x,g.player.shared_params._s_pos.y - last_s_pos.y, 0),90);
			g.player.rotation += shortest_angle(g.player.rotation, tar_rotation) * 0.25;
			
			[g.player apply_s_pos:g];
			
			[g.player play_anim:@"Dive" repeat:YES];
			if (g.player.position.y < 0) {
				[g.player pop_state_stack:g];
				[g.player push_state_stack:[DivePlayerStateStack cons:g]];
				
				
				[g shake_slow_for:100 distance:10];
				[g add_ripple:ccp(g.player.position.x,0)];
			}
		break;
		default:;
	}
}

-(PlayerState)get_state {
	return PlayerState_OnGround;
}

-(BOOL)on_land:(GameEngineScene *)game {
	return _land_params._current_mode == PlayerLandMode_OnDock;
}

@end
