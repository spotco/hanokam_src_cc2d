#ifndef COMMON_H
#define COMMON_H
#import "cocos2d.h"
#import "Vec3D.h"

@interface NSString (md5)
-(long)md5;
@end

@interface CCSprite_Animated : CCSprite
@property(readwrite,strong) CCAction *_current_anim;
-(void)update_playAnim:(CCAction*)anim;
@end

@interface CCNode (helpers)
-(CCNode*)set_pos:(CGPoint)pt;
-(CCNode*)set_scale:(float)scale;
-(CCNode*)set_scale_x:(float)scale_x;
-(CCNode*)set_scale_y:(float)scale_y;
-(CCNode*)set_rotation:(float)rotation;
-(CCNode*)set_color:(ccColor3B)color;
-(CCNode*)set_visible:(BOOL)visible;
-(CCNode*)set_anchor_pt:(CGPoint)pt;
-(CCNode*)add_to:(CCNode*)parent;
-(CCNode*)add_to:(CCNode*)parent z:(NSInteger)z;
-(CCNode*)add_on:(CCNode*)child;
@end

@interface NSArray (Random)
	-(id)random;
	-(NSArray*)copy_removing:(NSArray*)a;
	-(BOOL)contains_str:(NSString*)tar;
	-(id)get:(int)i;
@end

@interface NSMutableArray (Shuffle)
	-(void)shuffle;
	-(id)add:(id)i;
@end

@interface NSDictionary (KeySet)
	-(NSMutableSet*)keySet;
@end



@interface CallBack : NSObject
	@property(readwrite,assign) SEL selector;
	@property(readwrite,strong) NSObject *target;
	@property(readwrite,strong) id context;
@end

typedef struct _fCGPoint {
	float x;
	float y;
} fCGPoint; //64bit opengl PLS USE FLOATS

fCGPoint fCGPointMake(float x, float y);
#define fccp(x,y) fCGPointMake(x, y)
#define ccp2fccp(p) fCGPointMake(p.x,p.y)
#define fccp2ccp(p) CGPointMake(p.x,p.y)

@interface GLRenderObject : NSObject {
        fCGPoint tri_pts[4];
        fCGPoint tex_pts[4];
    }
    @property(readwrite,strong) CCTexture* texture;
    @property(readwrite,assign) int isalloc,pts;
	@property(readwrite,assign) fCGPoint transform;
    -(fCGPoint*)tri_pts;
    -(fCGPoint*)tex_pts;
@end

@interface TexRect : NSObject
	@property(readwrite,strong) CCTexture* tex;
	@property(readwrite,assign) CGRect rect;
	+(TexRect*)cons_tex:(CCTexture*)tex rect:(CGRect)rect;
@end

typedef enum HorizDir {
	HorizDir_Left,
	HorizDir_Right
} HorizDir;

typedef enum VertDir {
	VertDir_Top,
	VertDir_Bottom
} VertDir;

typedef struct HitRect {
    float x1,y1,x2,y2;
} HitRect;

typedef struct line_seg {
    CGPoint a;
    CGPoint b;
} line_seg;

typedef struct CameraZoom {
    float x;
    float y;
    float z;
} CameraZoom;

typedef struct CGRange {
    float min,max;
} CGRange;
CGRange CGRangeMake(float min, float max);

CGRect cctexture_default_rect(CCTexture *tex);

#define _NSSET(...)  [NSMutableSet setWithArray:@[__VA_ARGS__]]
#define _NSMARRAY(...)  [NSMutableArray arrayWithArray:@[__VA_ARGS__]]
#define _CCColor(x) [CCColor colorWithCcColor3b:x]
#define NSVEnum(val,type) [NSValue value:&val withObjCType:@encode(type)]

#define float_random(smallNumber, bigNumber) ((((float) (arc4random() % ((unsigned)RAND_MAX + 1)) / RAND_MAX) * (bigNumber - smallNumber)) + smallNumber)
#define int_random(s,l) arc4random()%l+s
#define streq(a,b) [a isEqualToString:b]
#define strcontains(_a,_b) ([_a rangeOfString:_b].location != NSNotFound)
#define DO_FOR(cts,a) for(int i = 0; i < cts; i++) { a; }
float drpt(float a, float b, float fric);
float lerp(float a, float b, float t);
CGPoint lerp_point(CGPoint a, CGPoint b, float t);
long sys_time();

NSString* strf (char* format, ... );

int SIG(float n);
bool fuzzyeq(float a, float b, float delta);
float deg_to_rad(float degrees);
float rad_to_deg(float rad);
float shortest_angle(float a1, float a2);
float cubic_angular_interp(float src, float dest, float c1, float c2, float t);

CGPoint CGPointAdd(CGPoint a,CGPoint b);
CGPoint CGPointSub(CGPoint a,CGPoint b);
float CGPointDist(CGPoint a,CGPoint b);
CGPoint CGPointMult(CGPoint a, CGPoint b);
CGPoint CGPointMid(CGPoint a,CGPoint b);

void dt_set(CCTime dt);
void dt_unset();
float dt_scale_get();

CGPoint pct_of_obj(CCNode* obj, float pctx, float pcty);

CGSize game_screen();
CGPoint game_screen_pct(float pctwid, float pcthei);

typedef enum _ScreenAnchor {
	ScreenAnchor_TL,
	ScreenAnchor_TM,
	ScreenAnchor_TR,
	ScreenAnchor_ML,
	ScreenAnchor_MM,
	ScreenAnchor_MR,
	ScreenAnchor_BL,
	ScreenAnchor_BM,
	ScreenAnchor_BR
} ScreenAnchor;
CGPoint game_screen_anchor_offset(ScreenAnchor anchor, CGPoint offset);

void scale_to_fit_screen_x(CCSprite *spr);
void scale_to_fit_screen_y(CCSprite *spr);

void callback_run(CallBack *c);
CallBack* callback_cons(NSObject *tar, SEL sel, id context);

HitRect hitrect_cons_x1y1_x2y2(float x1, float y1, float x2, float y2);
HitRect hitrect_cons_xy_widhei(float x1, float y1, float wid, float hei);
CGRect hitrect_to_cgrect(HitRect rect);
BOOL hitrect_touch(HitRect r1, HitRect r2);
BOOL hitrect_contains_point(HitRect rect, CGPoint pt);

CGPoint line_seg_intersection_pts(CGPoint a1, CGPoint a2, CGPoint b1, CGPoint b2);
CGPoint line_seg_intersection(line_seg a, line_seg b);
line_seg line_seg_cons(CGPoint a, CGPoint b);
CGFloat SEG_NO_VALUE();

GLRenderObject* render_object_cons(CCTexture* tex, int npts);
void render_object_draw(CCRenderer* renderer, CCRenderState *renderState, const GLKMatrix4 *transform, GLRenderObject *obj);
void render_object_tex_map_to_tri_loc(GLRenderObject *o, int len);
void render_object_transform(GLRenderObject* o, CGPoint position);

CameraZoom camerazoom_cons(float x, float y, float z);

CGRect rect_from_dict(NSDictionary* dict, NSString* tar);
CCAction* animaction_cons(NSArray *a, float speed, NSString *tex_key);
CCAction* animaction_nonrepeating_cons(NSArray *a, float speed, NSString *tex_key);

NSString* platform();
NSString* unique_id();
CCLabelTTF* label_cons(CGPoint pos, ccColor3B color, int fontSize, NSString* str);

CGPoint bezier_point_for_t(CGPoint p0, CGPoint p1, CGPoint p2, CGPoint p3, float t);
float cubic_interp(float a, float b, float c1, float c2, float t);

float signum(float value);
float low_filter(float value, float min);
Vec3D vec_from_ccrotation(float rotation);

CCSprite* flipper_cons_for(CCSprite* obj, float scx, float scy);

float running_avg(float avg, float val, float ct);
CGPoint point_box_intersection(CGSize box_size, Vec3D dir_vec);
CGRect scale_rect(CGRect tar, float scf);

NSArray* string_dofor_format(int ct, NSString* (^callback)(int i));

float y_for_point_of_2pt_line(CGPoint pt1, CGPoint pt2, float x);

BOOL ccnode_is_visible(CCNode* tar);

#endif