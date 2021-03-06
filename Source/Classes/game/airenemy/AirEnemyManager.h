//
//  AirEnemyManager.h
//  hobobob
//
//  Created by spotco on 27/03/2015.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Common.h"
#import "PolyLib.h"
@class GameEngineScene;


typedef enum PlayerHitType {
	PlayerHitType_Projectile,
	PlayerHitType_Melee,
	PlayerHitType_ChargedProjectile
} PlayerHitType;

typedef struct PlayerHitParams {
	Vec3D _dir;
	float _pushback_force;
	PlayerHitType _type;
	long _id;
} PlayerHitParams;
void PlayerHitParams_init(PlayerHitParams *params, PlayerHitType type,Vec3D dir);
long PlayerHitParams_idalloc();

@interface BaseAirEnemy : CCSprite <SATPolyHitOwner>
-(void)i_update:(GameEngineScene*)game;
-(BOOL)should_remove;
-(void)do_remove:(GameEngineScene*)g;
-(HitRect)get_hit_rect;
-(void)get_sat_poly:(SATPoly *)in_poly;
-(void)hit:(GameEngineScene*)g params:(PlayerHitParams*)params;
-(BOOL)is_alive;
-(BOOL)is_stunned;

-(BOOL)arrow_will_stick;
-(BOOL)arrow_drop_all;

-(CGPoint)get_healthbar_offset;
-(float)get_health_pct;
-(BOOL)should_show_health_bar;

+(void)particle_blood_effect:(GameEngineScene*)g pos:(CGPoint)pos ct:(int)ct;
@end

@interface AirEnemyManager : NSObject
+(AirEnemyManager*)cons:(GameEngineScene*)g;
-(void)i_update:(GameEngineScene*)game;
-(void)add_enemy:(BaseAirEnemy*)enemy game:(GameEngineScene*)game;
-(NSArray*)get_enemies;
-(NSArray*)get_enemies_future_spawn;
-(void)remove_all_enemies:(GameEngineScene*)g;
@end

@interface BaseAirEnemyFutureSpawn : NSObject
+(BaseAirEnemyFutureSpawn*)cons_time:(float)time screen:(CGPoint)screen enemy:(BaseAirEnemy*)enemy;
-(void)i_update:(GameEngineScene*)mgr;
-(BOOL)should_remove;
-(void)do_remove:(GameEngineScene*)mgr;
-(float)get_ct;
-(float)get_ctmax;
-(CGPoint)get_screen_pos;
@end