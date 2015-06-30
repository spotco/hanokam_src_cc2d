//
//  DiveReturnPlayerState.m
//  hanokam
//
//  Created by spotco on 06/06/2015.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "DiveReturnPlayerStateStack.h"
#import "PlayerUnderwaterCombatParams.h"
#import "InAirPlayerStateStack.h"

@implementation DiveReturnPlayerStateStack {
	PlayerUnderwaterCombatParams *_underwater_params;
}

+(DiveReturnPlayerStateStack*)cons:(GameEngineScene*)g waterparams:(PlayerUnderwaterCombatParams *)waterparams {
	return [[[DiveReturnPlayerStateStack alloc] init] cons:g waterparams:waterparams];
}

-(DiveReturnPlayerStateStack*)cons:(GameEngineScene*)g waterparams:(PlayerUnderwaterCombatParams *)waterparams  {
	_underwater_params = waterparams;
	return self;
}

-(void)i_update:(GameEngineScene *)g {
	g.player.shared_params._reset_to_center = YES;
	CGPoint last_pos = g.player.position;

	[g.player update_accel_x_position:g];
	_underwater_params._camera_offset = drpt(_underwater_params._camera_offset, 0, 1/10.0);
	_underwater_params._vel = ccp(_underwater_params._vel.x,MIN(_underwater_params._vel.y+0.2*dt_scale_get(), 30));
	g.player.position = ccp(g.player.position.x,g.player.position.y + _underwater_params._vel.y * dt_scale_get());
	
	float tar_rotation = vec_ang_deg_lim180(vec_cons(g.player.position.x - last_pos.x,g.player.position.y - last_pos.y, 0),90) + 15;
	g.player.rotation += shortest_angle(g.player.rotation, tar_rotation) * 0.25;
	if (g.player.position.y > 0) {
		[g.player pop_state_stack:g];
		[g.player push_state_stack:[InAirPlayerStateStack cons:g]];
		
		[g.player play_anim:@"In Air Idle" repeat:YES];
		[g add_ripple:ccp(g.player.position.x,0)];
	}
	[g.player read_s_pos:g];
	[g set_camera_height:g.player.position.y + _underwater_params._camera_offset];
	[g set_zoom:drpt(g.get_zoom,1.5,1/20.0)];
}

-(PlayerState)get_state {
	return PlayerState_DiveReturn;
}

@end
