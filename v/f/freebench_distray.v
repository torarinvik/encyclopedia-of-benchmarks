// Independent bounded FreeBench/distray profile.
// Ray-tracer attribution: Marcus Geelnard; benchmarkification: Peter Rundberg.
// The pinned upstream source has no explicit license grant.
module main
import math

const width = 640
const height = 480
const epsilon = 1.0e-5
const max_t = 1.0e5
const max_rec = 6
const dist_levels = 3

struct Vec3 { x f64; y f64; z f64 }
struct Texture { color Vec3; diffuse f64; reflect f64; roughness f64 }
struct Sphere { center Vec3; radius f64; texture Texture }
struct Hit { t f64; point Vec3; normal Vec3; texture Texture }
struct Context { distribution int; state u64 }

fn sphere_at(i int) Sphere {
    return match i {
        0 { Sphere{Vec3{0.0,4.0,1.0},1.0,Texture{Vec3{1.0,0.4,0.0},0.4,0.8,0.02}} }
        1 { Sphere{Vec3{-1.0,3.0,0.4},0.4,Texture{Vec3{0.5,0.3,1.0},0.5,0.9,0.01}} }
        2 { Sphere{Vec3{-0.3,1.0,0.4},0.4,Texture{Vec3{0.1,0.95,0.2},0.6,0.8,0.01}} }
        else { Sphere{Vec3{1.0,2.0,0.4},0.4,Texture{Vec3{0.86,0.83,0.0},0.7,0.6,0.01}} }
    }
}
fn ground_at(i int) Texture {
    if i == 0 { return Texture{Vec3{0.0,0.1,0.5},0.8,0.44,0.02} }
    return Texture{Vec3{0.6,1.0,0.5},0.8,0.44,0.01}
}
const light = Vec3{-3.0,1.0,5.0}
const camera = Vec3{1.5,-1.4,1.2}
const camera_right = Vec3{3.0,1.0,0.0}
const camera_dir = Vec3{-1.0,3.0,0.0}
const camera_up = Vec3{0.0,0.0,2.3717}
const sky_horizon = Vec3{0.5,0.3,0.7}
const sky_zenith = Vec3{0.0,0.0,0.2}

fn add(a Vec3,b Vec3) Vec3 { return Vec3{a.x+b.x,a.y+b.y,a.z+b.z} }
fn sub(a Vec3,b Vec3) Vec3 { return Vec3{a.x-b.x,a.y-b.y,a.z-b.z} }
fn mul(a Vec3,s f64) Vec3 { return Vec3{a.x*s,a.y*s,a.z*s} }
fn dot(a Vec3,b Vec3) f64 { return a.x*b.x+a.y*b.y+a.z*b.z }
fn vlen(a Vec3) f64 { return math.sqrt(dot(a,a)) }
fn jitter(mut c &Context) f64 {
    c.state = (u64(1103515245)*c.state+u64(12345)) & u64(0x7fffffff)
    return 1.0-f64(c.state)/f64(0x3fffffff)
}
fn distributed(mut c &Context,n Vec3,sa f64,sb f64) Vec3 {
    mut a:=Vec3{};mut b:=Vec3{}
    if math.abs(n.z)>epsilon { a=Vec3{n.y*n.z,-n.x*n.z,0.0};b=Vec3{a.y*n.z,-a.x*n.z,a.x*n.y-a.y*n.x} }
    else { a=Vec3{n.y,-n.x,0.0};b=Vec3{0.0,0.0,1.0} }
    nl:=vlen(n)
    a=mul(a,sa*(nl/vlen(a))*jitter(mut c))
    b=mul(b,sb*(nl/vlen(b))*jitter(mut c))
    return add(a,b)
}
fn reflected(d Vec3,n Vec3) Vec3 { return add(d,mul(n,-2.0*dot(d,n)/dot(n,n))) }
fn intersect(origin Vec3,d Vec3) Hit {
    mut h:=Hit{-1.0,Vec3{},Vec3{},ground_at(0)}
    if math.abs(d.z)>epsilon {
        t:= -origin.z/d.z
        if t>epsilon&&t<max_t { h.t=t;h.point=add(origin,mul(d,t));h.normal=Vec3{0.0,0.0,1.0};tile:=(int(h.point.x+50000.0)+int(h.point.y+50000.0))&1;h.texture=ground_at(tile) }
    }
    for i in 0..4 {
        sphere:=sphere_at(i);rel:=sub(sphere.center,origin);inv:=1.0/dot(d,d);b:=dot(rel,d)*inv
        c:=(sphere.radius*sphere.radius-dot(rel,rel))*inv;disc:=c+b*b
        if disc>0.0 { root:=math.sqrt(disc);mut t:=b-root;if t<epsilon { t=b+root };if t>epsilon&&(t<h.t||h.t<0.0){h.t=t;local:=mul(d,t);h.normal=sub(local,rel);h.point=add(local,origin);h.texture=sphere.texture} }
    }
    return h
}
fn trace(mut c &Context,origin Vec3,d Vec3,rec int) Vec3 {
    if rec<=0 { return Vec3{} }
    usedist:=(max_rec-rec)<dist_levels;h:=intersect(origin,d);mut color:=Vec3{}
    if h.t>epsilon {
        ld:=sub(light,h.point);cosine:=dot(ld,h.normal);mut amount:=0.0
        if cosine>0.0 {
            mut visible:=0
            if usedist { rs:=0.4/vlen(ld);for _ in 0..c.distribution { off:=distributed(mut c,ld,rs,rs);sh:=intersect(h.point,add(ld,off));if sh.t<epsilon||sh.t>1.0 { visible++ } } }
            else { sh:=intersect(h.point,ld);if sh.t<epsilon||sh.t>1.0 { visible=c.distribution } }
            if visible>0 { norm:=dot(h.normal,h.normal)*dot(ld,ld);amount=cosine/math.sqrt(norm)*h.texture.diffuse*f64(visible)/f64(c.distribution) }
        }
        color=mul(h.texture.color,0.3+amount)
        if h.texture.reflect>epsilon {
            rd:=reflected(d,h.normal);mut rc:=Vec3{}
            if usedist&&h.texture.roughness>epsilon { for _ in 0..c.distribution { off:=distributed(mut c,rd,h.texture.roughness,h.texture.roughness);rc=add(rc,trace(mut c,h.point,add(rd,off),rec-1)) };rc=mul(rc,1.0/f64(c.distribution)) }
            else { rc=trace(mut c,h.point,rd,rec-1) }
            color=add(color,mul(rc,h.texture.reflect))
        }
    } else {
        horizontal:=math.sqrt(d.x*d.x+d.y*d.y);mut blend:=1.0
        if horizontal>0.0 { blend=math.atan(math.abs(d.z)/horizontal)*0.63661977 }
        color=add(mul(sky_zenith,blend),mul(sky_horizon,1.0-blend))
    }
    if color.x>1.0 { color.x=1.0 };if color.y>1.0 { color.y=1.0 };if color.z>1.0 { color.z=1.0 }
    return color
}

@[export: 'freebench_distray']
pub fn freebench_distray(input &i64,input_length usize,output &u8,output_capacity usize) i64 {
    if unsafe{input==nil}||input_length!=3 { return -1 }
    distrib:=unsafe{input[0]};x:=unsafe{input[1]};y:=unsafe{input[2]}
    if distrib<1||distrib>5||x<0||x>=width||y<0||y>=height { return -1 }
    if unsafe{output==nil}||output_capacity<3 { return -2 }
    mut ctx:=Context{int(distrib),u64(0x52462467)}
    sx:=f64(x-width/2)/f64(width);sz:=f64(height/2-y)/f64(height)
    d:=Vec3{camera_right.x*sx+camera_dir.x+camera_up.x*sz,camera_right.y*sx+camera_dir.y+camera_up.y*sz,camera_right.z*sx+camera_dir.z+camera_up.z*sz}
    mut color:=Vec3{}
    for _ in 0..ctx.distribution { off:=distributed(mut ctx,d,0.5/f64(width),0.5/f64(height));color=add(color,trace(mut ctx,camera,add(d,off),max_rec)) }
    color=mul(color,1.0/f64(ctx.distribution))
    unsafe { output[0]=u8(int(color.x*255.0)&0xfe);output[1]=u8(int(color.y*255.0)&0xfe);output[2]=u8(int(color.z*255.0)&0xfe) }
    return 3
}
