#import "Common.h"

typedef struct SATPoly {
    CGPoint pts[4];
    int length;
} SATPoly;

@protocol SATPolyHitOwner <NSObject>
@required
-(void)get_sat_poly:(SATPoly*)in_poly;
-(HitRect)get_hit_rect;
@end

NSString* SAT_poly_to_str(SATPoly* buf);
void SAT_hitrect_to_poly(SATPoly* buf, HitRect rect);
void SAT_cons_quad_buf(SATPoly* buf, CGPoint a, CGPoint b, CGPoint c, CGPoint d);
BOOL SAT_polyowners_intersect(id<SATPolyHitOwner> a, id<SATPolyHitOwner> b);
HitRect SAT_poly_to_bounding_hitrect(SATPoly *buf, CGPoint extend_min, CGPoint extend_max);

HitRect satpolyowner_cons_hit_rect(CGPoint position, float sizex, float sizey, float scf);
void satpolyowner_cons_sat_poly(SATPoly *in_poly, CGPoint position, float rotation, float sizex, float sizey, CGPoint mul_scf, float scf);
void satpolyowner_cons_sat_poly_with_basis_offset(SATPoly *in_poly, CGPoint position, float rotation, float sizex, float sizey, CGPoint mul_scf, float scf, CGPoint basis_offset);