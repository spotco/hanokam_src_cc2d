#import "Resource.h"
#import "CCTextureCache.h"
#import "CCTexture_Private.h" 

#define _NSSET(...)  [NSMutableSet setWithArray:@[__VA_ARGS__]]
#define streq(a,b) [a isEqualToString:b]

@interface AsyncImgLoad : NSObject
+(AsyncImgLoad*)load:(NSString *)file key:(NSString*)key ;
@property(readwrite,assign) BOOL finished;
@property(readwrite,strong) NSString *key;
@property(readwrite,strong) CCTexture* tex;
@end

@implementation AsyncImgLoad
+(AsyncImgLoad*)load:(NSString *)file key:(NSString*)key {
	return [[AsyncImgLoad alloc] init_with:file key:key];
}
-(id)init_with:(NSString*)file key:(NSString*)key {
	self = [super init];
	self.finished = NO;
	self.key = key;
	
	[[CCTextureCache sharedTextureCache] addImageAsync:file target:self selector:@selector(on_finish:)];
	return self;
}
-(void)on_finish:(CCTexture*)tex {
	self.tex = tex;
	self.finished = YES;
}
@end

@implementation Resource


static NSDictionary* all_textures;
static NSMutableDictionary* loaded_textures;
static NSSet* dont_load;

+(void)initialize {
}

+(void)load_all {
	loaded_textures = [NSMutableDictionary dictionary];
	all_textures = @{
		TEX_BLANK: @"blank.png",
		TEX_TEST_BG_TILE_SKY: @"bg_test_tile_sky.png",
		TEX_TEST_BG_TILE_WATER: @"bg_test_tile_water.png",
		TEX_TEST_BG_UNDERWATER_SURFACE_GRADIENT: @"bg_underwater_surface_gradient.png",
		
		TEX_BG_WATER_TOP_BELOWLINE : @"bg_water_top_belowline.png",
		TEX_BG_WATER_TOP_WATERLINE : @"bg_water_top_waterline.png",
		TEX_BG_WATER_TOP_WATERLINEGRAD : @"bg_water_top_waterlinegrad.png",
		TEX_BG_WATER_BOTTOM_SURFACEGRAD : @"bg_water_bottom_surfacegrad.png",
		
		TEX_SPRITER_CHAR_OLDMAN: @"Oldman.png",
		TEX_SPRITER_CHAR_VILLAGER_FISHWOMAN: @"villager_fishwoman.png",
		TEX_SPRITER_CHAR_FISHGIRL: @"Fishgirl.png",
		
		TEX_SPRITER_CHAR_HANOKA_PLAYER: @"hanoka_player.png",
		TEX_SPRITER_CHAR_HANOKA_PLAYER_REDGARB: @"hanoka_player_redgarb.png",
		TEX_SPRITER_CHAR_HANOKA_BOW: @"hanoka_bow.png",
		TEX_SPRITER_CHAR_HANOKA_SWORD: @"hanoka_sword.png",
		
		TEX_ENEMY_PUFFER: @"puffer_enemy_ss.png",
		TEX_SPRITER_TEST: @"spriter_test.png",
		TEX_RIPPLE: @"ripple.png",
		
		TEX_EFFECTS_ENEMY: @"effects_enemy_ss.png",
		TEX_EFFECTS_HANOKA: @"effects_hanoka_ss.png",
		
		TEX_BG_SPRITESHEET_1: @"bg_spritesheet_1.png",
		TEX_BG_UNDERWATER_SPRITESHEET: @"underwater_spritesheet.png",
		TEX_BG_WATER_ELEMENT_FADE: @"bg_water_element_fade.png",
		TEX_BG_SKY_SPRITESHEET: @"sky_spritesheet.png",
		
		TEX_DIALOGUE_FONT : @"1hoonwhayang.png",

		TEX_UI_DIALOGUE_SPRITESHEET : @"dialog_ui_ss.png",
		TEX_UI_DIALOGUE_HEADICONS : @"headicons_ss.png",
		
		TEX_HUD_SPRITESHEET: @"hud_spritesheet.png",
		TEX_PARTICLES_SPRITESHEET: @"particles_spritesheet.png",
		TEX_GAMEPLAY_ELEMENTS: @"gameplay_elements_ss.png"
	};
	
	dont_load = _NSSET(
	);
	
	/*
	NSMutableArray *imgloaders = [NSMutableArray array];
	for (NSString *key in all_textures.keyEnumerator) {
		if ([dont_load containsObject:key]) continue;
		[imgloaders addObject:[AsyncImgLoad load:all_textures[key] key:key]];
	}
	NSMutableArray *to_remove = [NSMutableArray array];
	while ([imgloaders count] > 0) {
		for (AsyncImgLoad *loader in imgloaders) {
			if (loader.finished) {
				[loader.tex setAntiAliasTexParameters];
				loaded_textures[loader.key] = loader.tex;
				[to_remove addObject:loader];
				loader.tex = NULL;
			}
		}
		[imgloaders removeObjectsInArray:to_remove];
		[to_remove removeAllObjects];
		[NSThread sleepForTimeInterval:0.001];
	}
	*/
	
	for (NSString *key in all_textures) {
		CCTexture* tex = [[CCTextureCache sharedTextureCache] addImage:all_textures[key]];
		[tex setAntialiased:NO];
		loaded_textures[key] = tex;
	}
}

+(CCTexture*)get_tex:(NSString *)key {
	if (loaded_textures[key] != nil) {
		return loaded_textures[key];
	} else {
		CCTexture* tex = [[CCTextureCache sharedTextureCache] addImage:all_textures[key]];
		[tex setAntialiased:NO];
		loaded_textures[key] = tex;
		return loaded_textures[key];
	}
}

-(void)nullcb{}



@end
