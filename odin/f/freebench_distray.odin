// Independent bounded FreeBench/distray profile.
// Ray tracer attributed to Marcus Geelnard; benchmarkification to Peter
// Rundberg (biff@ce.chalmers.se). No upstream license grant is inferred.
package freebench_distray

import "core:c"
import "core:math"

WIDTH :: 640
HEIGHT :: 480
EPSILON :: 1.0e-5
MAX_T :: 1.0e5
MAX_REC :: 6
DIST_LEVELS :: 3

Vec3 :: struct { x, y, z: f64 }
Texture :: struct { color: Vec3, diffuse, reflect, roughness: f64 }
Sphere :: struct { center: Vec3, radius: f64, texture: Texture }
Hit :: struct { t: f64, point, normal: Vec3, texture: Texture }
Context :: struct { distribution: int, state: u64 }

SPHERES :: [4]Sphere{
	{{0.0,4.0,1.0},1.0,{{1.0,0.4,0.0},0.4,0.8,0.02}},
	{{-1.0,3.0,0.4},0.4,{{0.5,0.3,1.0},0.5,0.9,0.01}},
	{{-0.3,1.0,0.4},0.4,{{0.1,0.95,0.2},0.6,0.8,0.01}},
	{{1.0,2.0,0.4},0.4,{{0.86,0.83,0.0},0.7,0.6,0.01}},
}
GROUND :: [2]Texture{{{0.0,0.1,0.5},0.8,0.44,0.02},{{0.6,1.0,0.5},0.8,0.44,0.01}}
LIGHT :: Vec3 = {-3.0,1.0,5.0}
CAMERA :: Vec3 = {1.5,-1.4,1.2}
CAMERA_RIGHT :: Vec3 = {3.0,1.0,0.0}
CAMERA_DIR :: Vec3 = {-1.0,3.0,0.0}
CAMERA_UP :: Vec3 = {0.0,0.0,2.3717}
SKY_HORIZON :: Vec3 = {0.5,0.3,0.7}
SKY_ZENITH :: Vec3 = {0.0,0.0,0.2}

add :: proc "contextless" (a,b: Vec3)->Vec3 { return Vec3{a.x+b.x,a.y+b.y,a.z+b.z} }
sub :: proc "contextless" (a,b: Vec3)->Vec3 { return Vec3{a.x-b.x,a.y-b.y,a.z-b.z} }
mul :: proc "contextless" (a: Vec3,s: f64)->Vec3 { return Vec3{a.x*s,a.y*s,a.z*s} }
dot :: proc "contextless" (a,b: Vec3)->f64 { return a.x*b.x+a.y*b.y+a.z*b.z }
vlen :: proc "contextless" (a: Vec3)->f64 { return math.sqrt_f64(dot(a,a)) }

jitter :: proc "contextless" (ctx: ^Context)->f64 {
	ctx.state=(u64(1103515245)*ctx.state+u64(12345))&u64(0x7fffffff)
	return 1.0-f64(ctx.state)/f64(0x3fffffff)
}
distributed :: proc "contextless" (ctx:^Context,n:Vec3,sa,sb:f64)->Vec3 {
	a,b:Vec3
	if math.abs(n.z)>EPSILON { a=Vec3{n.y*n.z,-n.x*n.z,0.0};b=Vec3{a.y*n.z,-a.x*n.z,a.x*n.y-a.y*n.x} }
	else { a=Vec3{n.y,-n.x,0.0};b=Vec3{0.0,0.0,1.0} }
	nl:=vlen(n);a=mul(a,sa*(nl/vlen(a))*jitter(ctx));b=mul(b,sb*(nl/vlen(b))*jitter(ctx))
	return add(a,b)
}
reflect :: proc "contextless" (d,n:Vec3)->Vec3 { return add(d,mul(n,-2.0*dot(d,n)/dot(n,n))) }

intersect :: proc "contextless" (origin,d:Vec3)->Hit {
	h:=Hit{-1.0,{0.0,0.0,0.0},{0.0,0.0,0.0},GROUND[0]}
	if math.abs(d.z)>EPSILON {
		t:=-origin.z/d.z
		if t>EPSILON&&t<MAX_T { h.t=t;h.point=add(origin,mul(d,t));h.normal=Vec3{0.0,0.0,1.0};tile:=(int(h.point.x+50000.0)+int(h.point.y+50000.0))&1;h.texture=GROUND[tile] }
	}
	for sphere in SPHERES {
		relative:=sub(sphere.center,origin);inv:=1.0/dot(d,d);b:=dot(relative,d)*inv
		c:=(sphere.radius*sphere.radius-dot(relative,relative))*inv;disc:=c+b*b
		if disc>0.0 { root:=math.sqrt_f64(disc);t:=b-root;if t<EPSILON do t=b+root
			if t>EPSILON&&(t<h.t||h.t<0.0) { h.t=t;local:=mul(d,t);h.normal=sub(local,relative);h.point=add(local,origin);h.texture=sphere.texture }
		}
	}
	return h
}

trace :: proc "contextless" (ctx:^Context,origin,d:Vec3,recursion:int)->Vec3 {
	if recursion<=0 do return Vec3{0.0,0.0,0.0}
	usedist:=(MAX_REC-recursion)<DIST_LEVELS;h:=intersect(origin,d);color:=Vec3{0.0,0.0,0.0}
	if h.t>EPSILON {
		ld:=sub(LIGHT,h.point);cosine:=dot(ld,h.normal);amount:=0.0
		if cosine>0.0 {
			visible:=0
			if usedist { rs:=0.4/vlen(ld);for i:=0;i<ctx.distribution;i+=1 { off:=distributed(ctx,ld,rs,rs);sh:=intersect(h.point,add(ld,off));if sh.t<EPSILON||sh.t>1.0 do visible+=1 } }
			else { sh:=intersect(h.point,ld);if sh.t<EPSILON||sh.t>1.0 do visible=ctx.distribution }
			if visible>0 { norm:=dot(h.normal,h.normal)*dot(ld,ld);amount=(cosine/math.sqrt_f64(norm))*h.texture.diffuse*f64(visible)/f64(ctx.distribution) }
		}
		color=mul(h.texture.color,0.3+amount)
		if h.texture.reflect>EPSILON {
			rd:=reflect(d,h.normal);rc:=Vec3{0.0,0.0,0.0}
			if usedist&&h.texture.roughness>EPSILON { for i:=0;i<ctx.distribution;i+=1 { off:=distributed(ctx,rd,h.texture.roughness,h.texture.roughness);rc=add(rc,trace(ctx,h.point,add(rd,off),recursion-1)) };rc=mul(rc,1.0/f64(ctx.distribution)) }
			else { rc=trace(ctx,h.point,rd,recursion-1) }
			color=add(color,mul(rc,h.texture.reflect))
		}
	} else {
		horizontal:=math.sqrt_f64(d.x*d.x+d.y*d.y);blend:=1.0
		if horizontal>0.0 do blend=math.atan(math.abs(d.z)/horizontal)*0.63661977
		color=add(mul(SKY_ZENITH,blend),mul(SKY_HORIZON,1.0-blend))
	}
	color.x=min(color.x,1.0);color.y=min(color.y,1.0);color.z=min(color.z,1.0)
	return color
}

@(export)
freebench_distray :: proc "c" (input:[^]i64,input_length:c.size_t,output:[^]u8,output_capacity:c.size_t)->i64 {
	if input==nil||input_length!=3 do return -1
	distrib,x,y:=input[0],input[1],input[2]
	if distrib<1||distrib>5||x<0||x>=WIDTH||y<0||y>=HEIGHT do return -1
	if output==nil||output_capacity<3 do return -2
	ctx:=Context{int(distrib),u64(0x52462467)}
	sx:=f64(x-WIDTH/2)/f64(WIDTH);sz:=f64(HEIGHT/2-y)/f64(HEIGHT)
	d:=Vec3{CAMERA_RIGHT.x*sx+CAMERA_DIR.x+CAMERA_UP.x*sz,CAMERA_RIGHT.y*sx+CAMERA_DIR.y+CAMERA_UP.y*sz,CAMERA_RIGHT.z*sx+CAMERA_DIR.z+CAMERA_UP.z*sz}
	color:=Vec3{0.0,0.0,0.0}
	for i:=0;i<ctx.distribution;i+=1 { off:=distributed(&ctx,d,0.5/f64(WIDTH),0.5/f64(HEIGHT));color=add(color,trace(&ctx,CAMERA,add(d,off),MAX_REC)) }
	color=mul(color,1.0/f64(ctx.distribution))
	output[0]=u8(int(color.x*255.0)&0xfe);output[1]=u8(int(color.y*255.0)&0xfe);output[2]=u8(int(color.z*255.0)&0xfe)
	return 3
}
