// Independent bounded FreeBench/distray profile.
// Scene/ray-tracer attribution: Marcus Geelnard; benchmarkification:
// Peter Rundberg (biff@ce.chalmers.se). No upstream license grant inferred.
module freebench_distray;
import "math";

const int WIDTH=640, HEIGHT=480, MAX_REC=6, DIST_LEVELS=3;
const double EPSILON=1.0e-5, MAX_T=1.0e5;
struct Vec3 { double x; double y; double z; }
struct Texture { Vec3 color; double diffuse; double reflect; double roughness; }
struct Sphere { Vec3 center; double radius; Texture texture; }
struct Hit { double t; Vec3 point; Vec3 normal; Texture texture; }
struct Context { int distribution; ulong state; }

const Sphere[4] SPHERES={
    Sphere{Vec3{0.0,4.0,1.0},1.0,Texture{Vec3{1.0,0.4,0.0},0.4,0.8,0.02}},
    Sphere{Vec3{-1.0,3.0,0.4},0.4,Texture{Vec3{0.5,0.3,1.0},0.5,0.9,0.01}},
    Sphere{Vec3{-0.3,1.0,0.4},0.4,Texture{Vec3{0.1,0.95,0.2},0.6,0.8,0.01}},
    Sphere{Vec3{1.0,2.0,0.4},0.4,Texture{Vec3{0.86,0.83,0.0},0.7,0.6,0.01}}
};
const Texture[2] GROUND={
    Texture{Vec3{0.0,0.1,0.5},0.8,0.44,0.02},
    Texture{Vec3{0.6,1.0,0.5},0.8,0.44,0.01}
};
const Vec3 LIGHT=Vec3{-3.0,1.0,5.0};
const Vec3 CAMERA=Vec3{1.5,-1.4,1.2};
const Vec3 CAMERA_RIGHT=Vec3{3.0,1.0,0.0};
const Vec3 CAMERA_DIR=Vec3{-1.0,3.0,0.0};
const Vec3 CAMERA_UP=Vec3{0.0,0.0,2.3717};
const Vec3 SKY_HORIZON=Vec3{0.5,0.3,0.7};
const Vec3 SKY_ZENITH=Vec3{0.0,0.0,0.2};

fn Vec3 add(Vec3 a,Vec3 b){return Vec3{a.x+b.x,a.y+b.y,a.z+b.z};}
fn Vec3 sub(Vec3 a,Vec3 b){return Vec3{a.x-b.x,a.y-b.y,a.z-b.z};}
fn Vec3 mul(Vec3 a,double s){return Vec3{a.x*s,a.y*s,a.z*s};}
fn double dot(Vec3 a,Vec3 b){return a.x*b.x+a.y*b.y+a.z*b.z;}
fn double length(Vec3 a){return math.sqrt(dot(a,a));}
fn double jitter(Context* c){c.state=(1103515245ul*c.state+12345ul)&0x7ffffffful;return 1.0-(double)c.state/(double)0x3fffffff;}
fn Vec3 distributed(Context* c,Vec3 n,double sa,double sb){
    Vec3 a,b;
    if(math.abs(n.z)>EPSILON){a=Vec3{n.y*n.z,-n.x*n.z,0.0};b=Vec3{a.y*n.z,-a.x*n.z,a.x*n.y-a.y*n.x};}
    else{a=Vec3{n.y,-n.x,0.0};b=Vec3{0.0,0.0,1.0};}
    double nl=length(n);a=mul(a,sa*(nl/length(a))*jitter(c));b=mul(b,sb*(nl/length(b))*jitter(c));return add(a,b);
}
fn Vec3 reflect(Vec3 d,Vec3 n){return add(d,mul(n,-2.0*dot(d,n)/dot(n,n)));}
fn Hit intersect(Vec3 origin,Vec3 d){
    Hit h=Hit{-1.0,Vec3{0.0,0.0,0.0},Vec3{0.0,0.0,0.0},GROUND[0]};
    if(math.abs(d.z)>EPSILON){double t=-origin.z/d.z;if(t>EPSILON&&t<MAX_T){h.t=t;h.point=add(origin,mul(d,t));h.normal=Vec3{0.0,0.0,1.0};int tile=((int)(h.point.x+50000.0)+(int)(h.point.y+50000.0))&1;h.texture=GROUND[tile];}}
    for(int i=0;i<4;i++){Sphere s=SPHERES[i];Vec3 rel=sub(s.center,origin);double inv=1.0/dot(d,d);double b=dot(rel,d)*inv;double c=(s.radius*s.radius-dot(rel,rel))*inv;double disc=c+b*b;if(disc>0.0){double root=math.sqrt(disc);double t=b-root;if(t<EPSILON)t=b+root;if(t>EPSILON&&(t<h.t||h.t<0.0)){h.t=t;Vec3 local=mul(d,t);h.normal=sub(local,rel);h.point=add(local,origin);h.texture=s.texture;}}}
    return h;
}
fn Vec3 trace(Context* c,Vec3 origin,Vec3 d,int recursion){
    Vec3 color=Vec3{0.0,0.0,0.0};if(recursion<=0)return color;
    bool usedist=(MAX_REC-recursion)<DIST_LEVELS;Hit h=intersect(origin,d);
    if(h.t>EPSILON){
        Vec3 ld=sub(LIGHT,h.point);double cosine=dot(ld,h.normal);double amount=0.0;
        if(cosine>0.0){int visible=0;if(usedist){double rs=0.4/length(ld);for(int i=0;i<c.distribution;i++){Vec3 off=distributed(c,ld,rs,rs);Hit sh=intersect(h.point,add(ld,off));if(sh.t<EPSILON||sh.t>1.0)visible++;}}
            else{Hit sh=intersect(h.point,ld);if(sh.t<EPSILON||sh.t>1.0)visible=c.distribution;}
            if(visible>0){double norm=dot(h.normal,h.normal)*dot(ld,ld);amount=(cosine/math.sqrt(norm))*h.texture.diffuse*(double)visible/(double)c.distribution;}}
        color=mul(h.texture.color,0.3+amount);
        if(h.texture.reflect>EPSILON){Vec3 rd=reflect(d,h.normal);Vec3 rc=Vec3{0.0,0.0,0.0};if(usedist&&h.texture.roughness>EPSILON){for(int i=0;i<c.distribution;i++){Vec3 off=distributed(c,rd,h.texture.roughness,h.texture.roughness);rc=add(rc,trace(c,h.point,add(rd,off),recursion-1));}rc=mul(rc,1.0/(double)c.distribution);}else rc=trace(c,h.point,rd,recursion-1);color=add(color,mul(rc,h.texture.reflect));}
    }else{double horizontal=math.sqrt(d.x*d.x+d.y*d.y);double blend=horizontal>0.0?math.atan(math.abs(d.z)/horizontal)*0.63661977:1.0;color=add(mul(SKY_ZENITH,blend),mul(SKY_HORIZON,1.0-blend));}
    if(color.x>1.0)color.x=1.0;if(color.y>1.0)color.y=1.0;if(color.z>1.0)color.z=1.0;return color;
}
fn long freebench_distray(long* input,usz input_length,char* output,usz output_capacity) @export("freebench_distray"){
    if(input==null||input_length!=3)return -1;long distrib=input[0],x=input[1],y=input[2];if(distrib<1||distrib>5||x<0||x>=WIDTH||y<0||y>=HEIGHT)return -1;if(output==null||output_capacity<3)return -2;
    Context c=Context{(int)distrib,0x52462467ul};double sx=(double)(x-WIDTH/2)/(double)WIDTH;double sz=(double)(HEIGHT/2-y)/(double)HEIGHT;
    Vec3 d=Vec3{CAMERA_RIGHT.x*sx+CAMERA_DIR.x+CAMERA_UP.x*sz,CAMERA_RIGHT.y*sx+CAMERA_DIR.y+CAMERA_UP.y*sz,CAMERA_RIGHT.z*sx+CAMERA_DIR.z+CAMERA_UP.z*sz};Vec3 color=Vec3{0.0,0.0,0.0};
    for(int i=0;i<c.distribution;i++){Vec3 off=distributed(&c,d,0.5/(double)WIDTH,0.5/(double)HEIGHT);color=add(color,trace(&c,CAMERA,add(d,off),MAX_REC));}
    color=mul(color,1.0/(double)c.distribution);output[0]=(char)((int)(color.x*255.0)&0xfe);output[1]=(char)((int)(color.y*255.0)&0xfe);output[2]=(char)((int)(color.z*255.0)&0xfe);return 3;
}
