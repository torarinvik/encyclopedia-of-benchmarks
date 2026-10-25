// Independent bounded FreeBench/distray profile.
// Ray tracer attribution: Marcus Geelnard; benchmarkification: Peter Rundberg.
// The pinned upstream source has no explicit license grant.
const WIDTH: i64 = 640;
const HEIGHT: i64 = 480;
const EPSILON: f64 = 1.0e-5;
const MAX_T: f64 = 1.0e5;
const MAX_REC: i32 = 6;
const DIST_LEVELS: i32 = 3;

const Vec3 = struct { x: f64, y: f64, z: f64 };
const Texture = struct { color: Vec3, diffuse: f64, reflect: f64, roughness: f64 };
const Sphere = struct { center: Vec3, radius: f64, texture: Texture };
const Hit = struct { t: f64, point: Vec3, normal: Vec3, texture: Texture };
const Context = struct { distribution: i32, state: u64 };

const SPHERES = [_]Sphere{
    .{ .center=.{.x=0.0,.y=4.0,.z=1.0}, .radius=1.0, .texture=.{.color=.{.x=1.0,.y=0.4,.z=0.0},.diffuse=0.4,.reflect=0.8,.roughness=0.02} },
    .{ .center=.{.x=-1.0,.y=3.0,.z=0.4}, .radius=0.4, .texture=.{.color=.{.x=0.5,.y=0.3,.z=1.0},.diffuse=0.5,.reflect=0.9,.roughness=0.01} },
    .{ .center=.{.x=-0.3,.y=1.0,.z=0.4}, .radius=0.4, .texture=.{.color=.{.x=0.1,.y=0.95,.z=0.2},.diffuse=0.6,.reflect=0.8,.roughness=0.01} },
    .{ .center=.{.x=1.0,.y=2.0,.z=0.4}, .radius=0.4, .texture=.{.color=.{.x=0.86,.y=0.83,.z=0.0},.diffuse=0.7,.reflect=0.6,.roughness=0.01} },
};
const GROUND = [_]Texture{
    .{ .color=.{.x=0.0,.y=0.1,.z=0.5}, .diffuse=0.8, .reflect=0.44, .roughness=0.02 },
    .{ .color=.{.x=0.6,.y=1.0,.z=0.5}, .diffuse=0.8, .reflect=0.44, .roughness=0.01 },
};
const LIGHT = Vec3{.x=-3.0,.y=1.0,.z=5.0};
const CAMERA = Vec3{.x=1.5,.y=-1.4,.z=1.2};
const CAMERA_RIGHT = Vec3{.x=3.0,.y=1.0,.z=0.0};
const CAMERA_DIR = Vec3{.x=-1.0,.y=3.0,.z=0.0};
const CAMERA_UP = Vec3{.x=0.0,.y=0.0,.z=2.3717};
const SKY_HORIZON = Vec3{.x=0.5,.y=0.3,.z=0.7};
const SKY_ZENITH = Vec3{.x=0.0,.y=0.0,.z=0.2};

fn add(a: Vec3, b: Vec3) Vec3 { return .{.x=a.x+b.x,.y=a.y+b.y,.z=a.z+b.z}; }
fn sub(a: Vec3, b: Vec3) Vec3 { return .{.x=a.x-b.x,.y=a.y-b.y,.z=a.z-b.z}; }
fn mul(a: Vec3, s: f64) Vec3 { return .{.x=a.x*s,.y=a.y*s,.z=a.z*s}; }
fn dot(a: Vec3, b: Vec3) f64 { return a.x*b.x+a.y*b.y+a.z*b.z; }
fn vlen(a: Vec3) f64 { return @sqrt(dot(a,a)); }

fn jitter(ctx: *Context) f64 {
    ctx.state=(1103515245*ctx.state+12345)&0x7fffffff;
    return 1.0-@as(f64,@floatFromInt(ctx.state))/@as(f64,@floatFromInt(0x3fffffff));
}
fn distributed(ctx: *Context, n: Vec3, sa: f64, sb: f64) Vec3 {
    var a: Vec3=undefined;
    var b: Vec3=undefined;
    if (@abs(n.z)>EPSILON) {
        a=.{.x=n.y*n.z,.y=-n.x*n.z,.z=0.0};
        b=.{.x=a.y*n.z,.y=-a.x*n.z,.z=a.x*n.y-a.y*n.x};
    } else {
        a=.{.x=n.y,.y=-n.x,.z=0.0};
        b=.{.x=0.0,.y=0.0,.z=1.0};
    }
    const nl=vlen(n);
    a=mul(a,sa*(nl/vlen(a))*jitter(ctx));
    b=mul(b,sb*(nl/vlen(b))*jitter(ctx));
    return add(a,b);
}
fn reflected(d: Vec3, n: Vec3) Vec3 { return add(d,mul(n,-2.0*dot(d,n)/dot(n,n))); }

fn intersect(origin: Vec3, d: Vec3) Hit {
    var h=Hit{.t=-1.0,.point=.{.x=0.0,.y=0.0,.z=0.0},.normal=.{.x=0.0,.y=0.0,.z=0.0},.texture=GROUND[0]};
    if (@abs(d.z)>EPSILON) {
        const t=-origin.z/d.z;
        if (t>EPSILON and t<MAX_T) {
            h.t=t;h.point=add(origin,mul(d,t));h.normal=.{.x=0.0,.y=0.0,.z=1.0};
            const tile=@as(usize,@intCast((@as(i32,@intFromFloat(h.point.x+50000.0))+@as(i32,@intFromFloat(h.point.y+50000.0)))&1));
            h.texture=GROUND[tile];
        }
    }
    for (SPHERES) |sphere| {
        const relative=sub(sphere.center,origin);const inv=1.0/dot(d,d);const b=dot(relative,d)*inv;
        const c=(sphere.radius*sphere.radius-dot(relative,relative))*inv;const disc=c+b*b;
        if (disc>0.0) {
            const root=@sqrt(disc);var t=b-root;if (t<EPSILON)t=b+root;
            if (t>EPSILON and (t<h.t or h.t<0.0)) { h.t=t;const local=mul(d,t);h.normal=sub(local,relative);h.point=add(local,origin);h.texture=sphere.texture; }
        }
    }
    return h;
}

fn trace(ctx: *Context, origin: Vec3, d: Vec3, recursion: i32) Vec3 {
    if (recursion<=0)return .{.x=0.0,.y=0.0,.z=0.0};
    const usedist=(MAX_REC-recursion)<DIST_LEVELS;const h=intersect(origin,d);var color:Vec3=undefined;
    if (h.t>EPSILON) {
        const ld=sub(LIGHT,h.point);const cosine=dot(ld,h.normal);var amount:f64=0.0;
        if (cosine>0.0) {
            var visible:i32=0;
            if (usedist) { const rs=0.4/vlen(ld);for (0..@intCast(ctx.distribution)) |_| { const off=distributed(ctx,ld,rs,rs);const sh=intersect(h.point,add(ld,off));if (sh.t<EPSILON or sh.t>1.0)visible+=1; } }
            else { const sh=intersect(h.point,ld);if (sh.t<EPSILON or sh.t>1.0)visible=ctx.distribution; }
            if (visible>0) { const norm=dot(h.normal,h.normal)*dot(ld,ld);amount=(cosine/@sqrt(norm))*h.texture.diffuse*@as(f64,@floatFromInt(visible))/@as(f64,@floatFromInt(ctx.distribution)); }
        }
        color=mul(h.texture.color,0.3+amount);
        if (h.texture.reflect>EPSILON) {
            const rd=reflected(d,h.normal);var rc=Vec3{.x=0.0,.y=0.0,.z=0.0};
            if (usedist and h.texture.roughness>EPSILON) { for (0..@intCast(ctx.distribution)) |_| { const off=distributed(ctx,rd,h.texture.roughness,h.texture.roughness);rc=add(rc,trace(ctx,h.point,add(rd,off),recursion-1)); }rc=mul(rc,1.0/@as(f64,@floatFromInt(ctx.distribution))); }
            else { rc=trace(ctx,h.point,rd,recursion-1); }
            color=add(color,mul(rc,h.texture.reflect));
        }
    } else {
        const horizontal=@sqrt(d.x*d.x+d.y*d.y);const blend=if(horizontal>0.0) @atan(@abs(d.z)/horizontal)*0.63661977 else 1.0;
        color=add(mul(SKY_ZENITH,blend),mul(SKY_HORIZON,1.0-blend));
    }
    if(color.x>1.0)color.x=1.0;if(color.y>1.0)color.y=1.0;if(color.z>1.0)color.z=1.0;return color;
}

pub export fn freebench_distray(input: [*c]const i64, input_length: usize, output: [*c]u8, output_capacity: usize) i64 {
    if(input==null or input_length!=3)return -1;
    const distribution=input[0];const x=input[1];const y=input[2];
    if(distribution<1 or distribution>5 or x<0 or x>=WIDTH or y<0 or y>=HEIGHT)return -1;
    if(output==null or output_capacity<3)return -2;
    var ctx=Context{.distribution=@intCast(distribution),.state=0x52462467};
    const sx=@as(f64,@floatFromInt(x-WIDTH/2))/@as(f64,@floatFromInt(WIDTH));
    const sz=@as(f64,@floatFromInt(HEIGHT/2-y))/@as(f64,@floatFromInt(HEIGHT));
    const d=Vec3{.x=CAMERA_RIGHT.x*sx+CAMERA_DIR.x+CAMERA_UP.x*sz,.y=CAMERA_RIGHT.y*sx+CAMERA_DIR.y+CAMERA_UP.y*sz,.z=CAMERA_RIGHT.z*sx+CAMERA_DIR.z+CAMERA_UP.z*sz};
    var color=Vec3{.x=0.0,.y=0.0,.z=0.0};
    for(0..@intCast(ctx.distribution)) |_| { const off=distributed(&ctx,d,0.5/@as(f64,@floatFromInt(WIDTH)),0.5/@as(f64,@floatFromInt(HEIGHT)));color=add(color,trace(&ctx,CAMERA,add(d,off),MAX_REC)); }
    color=mul(color,1.0/@as(f64,@floatFromInt(ctx.distribution)));
    output[0]=@intCast(@as(i32,@intFromFloat(color.x*255.0))&0xfe);output[1]=@intCast(@as(i32,@intFromFloat(color.y*255.0))&0xfe);output[2]=@intCast(@as(i32,@intFromFloat(color.z*255.0))&0xfe);
    return 3;
}
