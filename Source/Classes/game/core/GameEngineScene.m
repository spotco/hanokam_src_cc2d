#import "GameEngineScene.h"
#import "GameMain.h"
#import "Player.h"
#import "Common.h"
#import "BGVillage.h"
#import "BGWater.h"
#import "BGSky.h"
#import "Particle.h"
#import "ShaderManager.h"
#import "GameUI.h"
#import "Particle.h"
#import "TouchTrackingLayer.h"
#import "AirEnemyManager.h"
#import "WaterEnemyManager.h"
#import "ControlManager.h"
#import "Resource.h"
#import "PlayerProjectile.h"
#import "EnemyProjectile.h"
#import "GameMain.h"
#import "SpriterNodeCache.h"
#import "SPDeviceAccelerometer.h"
#import "GEventDispatcher.h"
#import "BGCharacterBase.h"

@implementation GameEngineScene {
	// UTILS
	float _tick;
	ControlManager *_controls;
	
	// EFFECTS
	float _shake_rumble_time, _shake_rumble_total_time, _shake_rumble_distance;
	float _shake_rumble_slow_time, _shake_rumble_slow_total_time, _shake_rumble_slow_distance;
	float _freeze;
	
	ParticleSystem *_particles;
	
	CCSprite *_ripple_proto;
	NSMutableArray *_ripples;
	
	GEventDispatcher *_event_dispatcher;
	
	// CAM
	CCNode *_zoom_node, *_game_anchor;
	
	float _current_zoom;
	float _current_camera_center_y;
	CGPoint _camera_center_point;
	
	// WORLD
	Player *_player;
	ParticleSystem *_player_projectiles;
	ParticleSystem *_enemy_projectiles;
	
	BGVillage *_bg_village;
	BGWater *_bg_water;
	BGSky *_bg_sky;
	NSArray *_bg_elements;
	
	AirEnemyManager *_air_enemy_manager;
	WaterEnemyManager *_water_enemy_manager;
    
    DelayActionQueue *_delay_action_queue;
	
	// GUI
	CCLabelTTF *_water_text;
	GameUI *_ui;
	TouchTrackingLayer *_touch_tracking;
	CCDrawNode *_debug_draw;
	
	CCRenderTexture *_blur_frame_tex;
	float _blur_ct;
	
}

-(Player*)player { return _player; }
-(float)tick { return _tick; }
-(AirEnemyManager*)get_air_enemy_manager { return _air_enemy_manager; }
-(WaterEnemyManager*)get_water_enemy_manager { return _water_enemy_manager; }
-(ControlManager*)get_control_manager { return _controls; }
-(GameUI*)get_ui{ return _ui; }
-(TouchTrackingLayer*)get_touch_tracking_layer{ return _touch_tracking; }
-(NSArray*)get_player_projectiles { return _player_projectiles.list; }

-(PlayerState)get_player_state {
	return _player.get_player_state;
}

+(GameEngineScene*)cons {
	return [[GameEngineScene node] cons];
}

-(float) REFLECTION_HEIGHT { return 250; }
-(float) HORIZON_HEIGHT { return 100; }
-(float) DOCK_HEIGHT { return 48; }

-(id)cons {
	self.userInteractionEnabled = YES;
	_controls = [ControlManager cons];
    _delay_action_queue = [DelayActionQueue cons];
	dt_unset();
	
	_event_dispatcher = [GEventDispatcher cons];
	
	_touch_tracking = [TouchTrackingLayer node];
	[super addChild:_touch_tracking z:99];
	
	_shake_rumble_total_time = _shake_rumble_time = _shake_rumble_distance = 1;
	_shake_rumble_slow_total_time = _shake_rumble_slow_time = _shake_rumble_slow_distance = 1;
	
	_zoom_node = [CCNode node];
	[super addChild:_zoom_node];
	
	_game_anchor = [[CCNode node] add_to:_zoom_node];
	
	_particles = [ParticleSystem cons_anchor:_game_anchor];
	_player_projectiles = [ParticleSystem cons_anchor:_game_anchor];
	_enemy_projectiles = [ParticleSystem cons_anchor:_game_anchor];
	
	[self reset_camera];
	_player = (Player*)[[Player cons_g:self] add_to:_game_anchor z:GameAnchorZ_Player];
	
	
	_ripples = [NSMutableArray array];
	_ripple_proto = [CCSprite spriteWithTexture:[Resource get_tex:TEX_RIPPLE]];
	_ripple_proto.shader = [ShaderManager get_shader:SHADER_RIPPLE_FX];
	
	_bg_village = [BGVillage cons:self];
	_bg_water = [BGWater cons:self];
	_bg_sky = [BGSky cons:self];
	_bg_elements = @[_bg_village, _bg_water, _bg_sky];
	
	_air_enemy_manager = [AirEnemyManager cons:self];
	_water_enemy_manager = [WaterEnemyManager cons:self];
	
	_ui = [GameUI cons:self];
	[super addChild:_ui z:GameAnchorZ_UI];
	
	_debug_draw = [CCDrawNode node];
	[[self get_anchor] addChild:_debug_draw z:GameAnchorZ_DebugDraw];
	
	[self update:0];
	
	_blur_frame_tex = [CCRenderTexture renderTextureWithWidth:game_screen().width height:game_screen().height pixelFormat:CCTexturePixelFormat_RGB565];
	[super addChild:_blur_frame_tex z:GameAnchorZ_BlurTex];
	[_blur_frame_tex.sprite setPosition:CGPointAdd(game_screen_pct(0.5,0.5),ccp(0,0))];
	
	return self;
}

-(void)reset_camera {
	_current_camera_center_y = 0;
	_current_zoom = 1;
}

-(void)add_player_projectile:(PlayerProjectile*)tar {
	[_player_projectiles add_particle:tar];
}

-(void)add_enemy_projectile:(EnemyProjectile*)tar {
	[_enemy_projectiles add_particle:tar];
}

-(void)addChild:(CCNode *)node { [NSException raise:@"Do not add children to GameEngineScene" format:@""]; }
-(NSArray*)get_ripple_infos { return _ripples; }
-(CCSprite*)get_ripple_proto { return _ripple_proto; }
-(NSNumber*)get_tick_mod_pi { return @(fmodf(_tick * 0.01,M_PI * 2)); }
-(BGVillage*)get_bg_village { return _bg_village; }
-(BGWater*)get_bg_water { return _bg_water; }
-(GEventDispatcher*)get_event_dispatcher { return _event_dispatcher; }

-(void)add_delayed_action:(DelayAction *)delayed_action {
    [_delay_action_queue enqueue_action:delayed_action];
}

-(void)add_ripple:(CGPoint)pos {
	if ([_ripples count] > 6) return;
	[_ripples addObject:[[RippleInfo alloc] initWithPosition:pos game:self]];
}

-(void)update_ripples {
	NSMutableArray *to_remove = [NSMutableArray array];
	for (RippleInfo *itr in _ripples) {
		if ([itr should_remove]) {
			[to_remove addObject:itr];
		} else {
			[itr i_update];
		}
	}
	[_ripples removeObjectsInArray:to_remove];
}

-(void)update:(CCTime)delta {
	dt_set(delta);
	
	[_controls accel_report_x:[SPDeviceAccelerometer accel_x]];
	
	_tick += dt_scale_get(); 
	
	if(_freeze > 0) {
		_freeze -= dt_scale_get();
		return;
	}
	
	
	[_controls i_update:self];
	[_player i_update:self];
	[self update_camera];
	[_particles update_particles:self];
	[_player_projectiles update_particles:self];
	[_enemy_projectiles update_particles:self];
    [_delay_action_queue i_update:dt_scale_get()];
	
	for (BGElement *itr in _bg_elements) {
		[itr i_update:self];
	}
	
	//TODO -- move these to their respective state stacks
	[_air_enemy_manager i_update:self];
	[_water_enemy_manager i_update:self];
	
	//TODO -- move this to bgwater
	[self update_ripples];
	
	[_ui i_update:self];
	
#ifdef HMCFG_DRAW_HITBOXES
	[self debug_draw_hitboxes];
#endif
	
	[self.get_control_manager clear_proc_swipe];
	[self.get_control_manager clear_proc_tap];
	
	if (_blur_ct > 0) {
		_blur_ct -= 0.03 * dt_scale_get();
		[_blur_frame_tex.sprite setOpacity:bezier_point_for_t(ccp(0,0.85), ccp(0,0), ccp(0.5,0), ccp(1,0),1-_blur_ct).y];
		[_blur_frame_tex setVisible:YES];
	} else {
		[_blur_frame_tex setVisible:NO];
	}
}

-(void)blur_and_pulse {
	_blur_ct = 1.0;
	[self update_camera];
	[_blur_frame_tex begin];
	[_ui setVisible:NO];
	[_blur_frame_tex.sprite setVisible:NO];
	[self visit];
	[_ui setVisible:YES];
	[_blur_frame_tex.sprite setVisible:YES];
	[_blur_frame_tex end];
	
}

-(void)add_particle:(Particle*)p {
	[_particles add_particle:p];
}

-(void)set_camera_height:(float)tar { _current_camera_center_y = tar; }
-(void)set_zoom:(float)tar { _current_zoom = tar; }
-(float)get_zoom { return _current_zoom; }
-(float)get_current_camera_center_y { return _current_camera_center_y; }

-(void)imm_set_zoom:(float)val {
	[_zoom_node setScale:clampf(val, 1, INFINITY)];
}

-(void)imm_set_camera_hei:(float)hei {
	_current_camera_center_y = hei;
	CGPoint pt = ccp(game_screen().width / 2, hei);
	_camera_center_point = pt;
	CGSize s = [CCDirector sharedDirector].viewSize;
	[_game_anchor setScale:1];
	CGPoint halfScreenSize = ccp(s.width / 2, s.height / 2);
	[_game_anchor setPosition:CGPointAdd(
		game_screen_pct(-.5, -.5),
	ccp(
		 halfScreenSize.x - pt.x,
		 halfScreenSize.y - pt.y
	))];
}

-(float)get_offset_current_zoom {
	return _current_zoom + ((_blur_ct <= 0) ? 0 :bezier_point_for_t(ccp(0,0), ccp(0.0,0.1), ccp(0.1,0), ccp(1.0,0), 1-_blur_ct).y);
}

-(void)touchBegan:(CCTouch *)touch withEvent:(CCTouchEvent *)event {
	CGPoint touch_position = [touch locationInWorld];
	[_touch_tracking touch_begin:touch_position];
	[_controls touch_begin:touch_position];
}
-(void)touchMoved:(CCTouch *)touch withEvent:(CCTouchEvent *)event {
	CGPoint touch_position = [touch locationInWorld];
	[_touch_tracking touch_move:touch_position];
	[_controls touch_move:touch_position];
}
-(void)touchEnded:(CCTouch *)touch withEvent:(CCTouchEvent *)event {
	CGPoint touch_position = [touch locationInWorld];
	[_touch_tracking touch_end:touch_position];
	[_controls touch_end:touch_position];
}

-(void)shake_for:(float)ct distance:(float)distance{
	_shake_rumble_time = _shake_rumble_total_time = ct;
	_shake_rumble_distance = distance;
}

-(void)shake_slow_for:(float)ct distance:(float)distance{
	_shake_rumble_slow_time = _shake_rumble_slow_total_time = ct;
	_shake_rumble_slow_distance = distance;
}

-(CGPoint)get_zoom_node_pos {
	CGPoint center = game_screen_pct(.5, .5);
	CGSize screen = game_screen();
	screen.width *= [self get_offset_current_zoom];
	screen.height *= [self get_offset_current_zoom];
	CGPoint delta_max = ccp(
		(screen.width - game_screen().width)/2/[self get_offset_current_zoom],
		(screen.height - game_screen().height)/2/[self get_offset_current_zoom]
	);
	HitRect view = [self get_viewbox];
	CGPoint screen_center = CGPointMid(ccp(view.x1,view.y1), ccp(view.x2,view.y2));
	CGPoint player_offset = CGPointSub(screen_center,_player.position);
	
	//y position is set
	CGPoint x_rel_y_final_pt = CGPointAdd(center, ccp(
		player_offset.x,
		clampf(player_offset.y, -delta_max.y, delta_max.y)
	));
	
	//player anchorpoint on the world
	CGPoint ppt = ccp((_player.position.x - view.x1)/(view.x2-view.x1),(_player.position.y - view.y1)/(view.y2-view.y1));
	
	//rtv.y - game_screen().height*-(-ANCHORPOINT.x)*(_current_zoom-1)
	CGPoint rtv = ccp(
		x_rel_y_final_pt.x - game_screen().width*-(-ppt.x+0.5)*([self get_offset_current_zoom]-1),
		x_rel_y_final_pt.y
	);
	
	/*
	linear regression {{1,159},{1.3,207},{1.6,256},{2.1,335.03}}
	L: 160.179x - 1.01

	linear regression {{1,159},{1.3,111.2},{1.6,63.32},{2.1,-17}}
	R: 319.148-160.012x
	*/
	float xmin = 160.179*[self get_offset_current_zoom]-1.01;
	float xmax = 319.148-160.012*[self get_offset_current_zoom];
	rtv.x = clampf(rtv.x, xmin, xmax);
	return rtv;
	
}

-(void)update_camera {
	[self imm_set_zoom:[self get_offset_current_zoom]];
	[self imm_set_camera_hei:_current_camera_center_y];
	
	[_zoom_node setPosition:[self get_zoom_node_pos]];
	if(_shake_rumble_time > 0)
		_shake_rumble_time -= dt_scale_get();
	else
		_shake_rumble_time = 0;
	float _rumble_dist = _shake_rumble_distance * (_shake_rumble_time / _shake_rumble_total_time);
	[_zoom_node setPosition:CGPointAdd(_zoom_node.position, ccp(sinf(_tick * 1.2) * _rumble_dist, cosf(_tick * 1.2) * _rumble_dist))];
	if(_shake_rumble_slow_time > 0)
		_shake_rumble_slow_time -= dt_scale_get();
	else
		_shake_rumble_slow_time = 0;
	float _rumble_slow_dist = _shake_rumble_slow_distance * (_shake_rumble_slow_time / _shake_rumble_slow_total_time);
	[_zoom_node setPosition:CGPointAdd(_zoom_node.position, ccp(sinf(_tick / 3) * _rumble_slow_dist / 2, cosf(_tick / 3) * _rumble_slow_dist))];
}

//TODO -- this doesn't freeze animations
-(void)freeze_frame:(int)ct{
	_freeze = ct;
}
-(HitRect)get_viewbox{return hitrect_cons_xy_widhei(_camera_center_point.x - game_screen().width / 2, _camera_center_point.y - game_screen().height / 2, game_screen().width, game_screen().height); }
-(CCNode*)get_anchor { return _game_anchor; }
-(BOOL)fullScreenTouch { return YES; }

-(void)debug_draw_hitboxes {
	[_debug_draw clear];
	CCColor *player_color = [CCColor colorWithCcColor4f:ccc4f(0, 1, 0, 0.25)];
	CCColor *player_sat_color = [CCColor colorWithCcColor4f:ccc4f(0, 1, 0, 0.75)];
	CCColor *enemy_color = [CCColor colorWithCcColor4f:ccc4f(1, 0, 0, 0.25)];
	CCColor *enemy_sat_color = [CCColor colorWithCcColor4f:ccc4f(1, 0, 0, 0.75)];
	CCColor *projectile_color = [CCColor colorWithCcColor4f:ccc4f(1, 1, 0, 0.25)];
	CCColor *projectile_sat_color = [CCColor colorWithCcColor4f:ccc4f(1, 1, 0, 0.75)];
	CCColor *enemy_projectile_color = [CCColor colorWithCcColor4f:ccc4f(0.8, 0.4, 0, 0.25)];
	CCColor *enemy_projectile_sat_color = [CCColor colorWithCcColor4f:ccc4f(0.8, 0.4, 0, 0.75)];
	
	SATPoly itr_poly;
	
	[self draw_hit_rect:_player.get_hit_rect color:player_color];
	[_player get_sat_poly:&itr_poly];
	[self draw_sat_poly:&itr_poly color:player_sat_color];
	
	for (BaseAirEnemy *itr in _air_enemy_manager.get_enemies) {
		[self draw_hit_rect:itr.get_hit_rect color:enemy_color];
		[itr get_sat_poly:&itr_poly];
		[self draw_sat_poly:&itr_poly color:enemy_sat_color];
	}
	
	for (BaseWaterEnemy *itr in _water_enemy_manager.get_enemies) {
		[self draw_hit_rect:itr.get_hit_rect color:enemy_color];
		[itr get_sat_poly:&itr_poly];
		[self draw_sat_poly:&itr_poly color:enemy_sat_color];
	}
	
	for (PlayerProjectile *itr in _player_projectiles.list) {
		[self draw_hit_rect:itr.get_hit_rect color:projectile_color];
		[itr get_sat_poly:&itr_poly];
		[self draw_sat_poly:&itr_poly color:projectile_sat_color];
	}
	
	for (EnemyProjectile *itr in _enemy_projectiles.list) {
		[self draw_hit_rect:itr.get_hit_rect color:enemy_projectile_color];
		[itr get_sat_poly:&itr_poly];
		[self draw_sat_poly:&itr_poly color:enemy_projectile_sat_color];
	}
	
	for (BGCharacterBase *itr in _bg_village.get_villagers) {
		[self draw_hit_rect:[itr get_hit_rect:self] color:enemy_color];
	}
}

static CGPoint *__dhrbuf;
-(void)draw_hit_rect:(HitRect)hr color:(CCColor*)color {
	if (__dhrbuf == NULL) __dhrbuf = malloc(sizeof(CGPoint)*4);
	__dhrbuf[0] = ccp(hr.x1,hr.y1);
	__dhrbuf[1] = ccp(hr.x1,hr.y2);
	__dhrbuf[2] = ccp(hr.x2,hr.y2);
	__dhrbuf[3] = ccp(hr.x2,hr.y1);
	[_debug_draw drawPolyWithVerts:__dhrbuf count:4 fillColor:color borderWidth:0 borderColor:color];
}
-(void)draw_sat_poly:(SATPoly*)poly color:(CCColor*)color {
	if (__dhrbuf == NULL) __dhrbuf = malloc(sizeof(CGPoint)*4);
	__dhrbuf[0] = poly->pts[0];
	__dhrbuf[1] = poly->pts[1];
	__dhrbuf[2] = poly->pts[2];
	__dhrbuf[3] = poly->pts[3];
	[_debug_draw drawPolyWithVerts:__dhrbuf count:4 fillColor:color borderWidth:0 borderColor:color];
}

@end

@implementation BGElement
-(void)i_update:(GameEngineScene*)game{}
@end
