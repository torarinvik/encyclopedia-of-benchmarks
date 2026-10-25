// Independent bounded FreeBench/distray profile.
// Ray tracer attributed upstream to Marcus Geelnard; benchmarkification to
// Peter Rundberg (biff@ce.chalmers.se). No upstream license grant is inferred.
const WIDTH: i64 = 640;
const HEIGHT: i64 = 480;
const EPSILON: f64 = 1.0e-5;
const MAX_T: f64 = 1.0e5;
const MAX_REC: i32 = 6;
const DIST_LEVELS: i32 = 3;

#[derive(Clone, Copy)]
struct Vec3 { x: f64, y: f64, z: f64 }
#[derive(Clone, Copy)]
struct Texture { color: Vec3, diffuse: f64, reflect: f64, roughness: f64 }
#[derive(Clone, Copy)]
struct Sphere { center: Vec3, radius: f64, texture: Texture }
#[derive(Clone, Copy)]
struct Hit { t: f64, point: Vec3, normal: Vec3, texture: Texture }
struct Context { distribution: i32, state: u64 }

const SPHERES: [Sphere; 4] = [
    Sphere { center: Vec3{x:0.0,y:4.0,z:1.0}, radius:1.0, texture:Texture{color:Vec3{x:1.0,y:0.4,z:0.0},diffuse:0.4,reflect:0.8,roughness:0.02} },
    Sphere { center: Vec3{x:-1.0,y:3.0,z:0.4}, radius:0.4, texture:Texture{color:Vec3{x:0.5,y:0.3,z:1.0},diffuse:0.5,reflect:0.9,roughness:0.01} },
    Sphere { center: Vec3{x:-0.3,y:1.0,z:0.4}, radius:0.4, texture:Texture{color:Vec3{x:0.1,y:0.95,z:0.2},diffuse:0.6,reflect:0.8,roughness:0.01} },
    Sphere { center: Vec3{x:1.0,y:2.0,z:0.4}, radius:0.4, texture:Texture{color:Vec3{x:0.86,y:0.83,z:0.0},diffuse:0.7,reflect:0.6,roughness:0.01} },
];
const GROUND: [Texture; 2] = [
    Texture{color:Vec3{x:0.0,y:0.1,z:0.5},diffuse:0.8,reflect:0.44,roughness:0.02},
    Texture{color:Vec3{x:0.6,y:1.0,z:0.5},diffuse:0.8,reflect:0.44,roughness:0.01},
];
const LIGHT: Vec3 = Vec3{x:-3.0,y:1.0,z:5.0};
const CAMERA: Vec3 = Vec3{x:1.5,y:-1.4,z:1.2};
const CAMERA_RIGHT: Vec3 = Vec3{x:3.0,y:1.0,z:0.0};
const CAMERA_DIR: Vec3 = Vec3{x:-1.0,y:3.0,z:0.0};
const CAMERA_UP: Vec3 = Vec3{x:0.0,y:0.0,z:2.3717};
const SKY_HORIZON: Vec3 = Vec3{x:0.5,y:0.3,z:0.7};
const SKY_ZENITH: Vec3 = Vec3{x:0.0,y:0.0,z:0.2};

fn add(a: Vec3,b: Vec3)->Vec3{Vec3{x:a.x+b.x,y:a.y+b.y,z:a.z+b.z}}
fn sub(a: Vec3,b: Vec3)->Vec3{Vec3{x:a.x-b.x,y:a.y-b.y,z:a.z-b.z}}
fn mul(a: Vec3,s: f64)->Vec3{Vec3{x:a.x*s,y:a.y*s,z:a.z*s}}
fn dot(a: Vec3,b: Vec3)->f64{a.x*b.x+a.y*b.y+a.z*b.z}
fn length(a: Vec3)->f64{dot(a,a).sqrt()}

fn jitter(ctx: &mut Context)->f64{
    ctx.state=(1103515245u64*ctx.state+12345u64)&0x7fffffff;
    1.0-ctx.state as f64/0x3fffffff as f64
}
fn distributed(ctx:&mut Context,n:Vec3,sa:f64,sb:f64)->Vec3{
    let (mut a,mut b):(Vec3,Vec3);
    if n.z.abs()>EPSILON{a=Vec3{x:n.y*n.z,y:-n.x*n.z,z:0.0};b=Vec3{x:a.y*n.z,y:-a.x*n.z,z:a.x*n.y-a.y*n.x};}
    else{a=Vec3{x:n.y,y:-n.x,z:0.0};b=Vec3{x:0.0,y:0.0,z:1.0};}
    let nl=length(n);
    a=mul(a,sa*(nl/length(a))*jitter(ctx));
    b=mul(b,sb*(nl/length(b))*jitter(ctx));
    add(a,b)
}
fn reflect(incident:Vec3,n:Vec3)->Vec3{add(incident,mul(n,-2.0*dot(incident,n)/dot(n,n)))}

fn intersect(origin:Vec3,direction:Vec3)->Hit{
    let mut hit=Hit{t:-1.0,point:Vec3{x:0.0,y:0.0,z:0.0},normal:Vec3{x:0.0,y:0.0,z:0.0},texture:GROUND[0]};
    if direction.z.abs()>EPSILON{
        let candidate=-origin.z/direction.z;
        if candidate>EPSILON&&candidate<MAX_T{
            hit.t=candidate;hit.point=add(origin,mul(direction,candidate));hit.normal=Vec3{x:0.0,y:0.0,z:1.0};
            let tile=((hit.point.x+50000.0) as i32+(hit.point.y+50000.0) as i32)&1;hit.texture=GROUND[tile as usize];
        }
    }
    for sphere in SPHERES{
        let relative=sub(sphere.center,origin);let inv=1.0/dot(direction,direction);
        let projection=dot(relative,direction)*inv;
        let constant=(sphere.radius*sphere.radius-dot(relative,relative))*inv;
        let discriminant=constant+projection*projection;
        if discriminant>0.0{
            let root=discriminant.sqrt();let mut candidate=projection-root;if candidate<EPSILON{candidate=projection+root;}
            if candidate>EPSILON&&(candidate<hit.t||hit.t<0.0){
                hit.t=candidate;let local=mul(direction,candidate);hit.normal=sub(local,relative);hit.point=add(local,origin);hit.texture=sphere.texture;
            }
        }
    }
    hit
}

fn trace(ctx:&mut Context,origin:Vec3,direction:Vec3,recursion:i32)->Vec3{
    if recursion<=0{return Vec3{x:0.0,y:0.0,z:0.0};}
    let use_distribution=(MAX_REC-recursion)<DIST_LEVELS;
    let hit=intersect(origin,direction);
    let mut color:Vec3;
    if hit.t>EPSILON{
        let light_direction=sub(LIGHT,hit.point);let light_dot=dot(light_direction,hit.normal);let mut amount=0.0;
        if light_dot>0.0{
            let mut visible=0;
            if use_distribution{
                let scale=0.4/length(light_direction);
                for _ in 0..ctx.distribution{let offset=distributed(ctx,light_direction,scale,scale);let shadow=intersect(hit.point,add(light_direction,offset));if shadow.t<EPSILON||shadow.t>1.0{visible+=1;}}
            }else{let shadow=intersect(hit.point,light_direction);if shadow.t<EPSILON||shadow.t>1.0{visible=ctx.distribution;}}
            if visible>0{let norm=dot(hit.normal,hit.normal)*dot(light_direction,light_direction);amount=(light_dot/norm.sqrt())*hit.texture.diffuse*visible as f64/ctx.distribution as f64;}
        }
        color=mul(hit.texture.color,0.3+amount);
        if hit.texture.reflect>EPSILON{
            let reflected=reflect(direction,hit.normal);let mut reflected_color=Vec3{x:0.0,y:0.0,z:0.0};
            if use_distribution&&hit.texture.roughness>EPSILON{
                for _ in 0..ctx.distribution{let offset=distributed(ctx,reflected,hit.texture.roughness,hit.texture.roughness);reflected_color=add(reflected_color,trace(ctx,hit.point,add(reflected,offset),recursion-1));}
                reflected_color=mul(reflected_color,1.0/ctx.distribution as f64);
            }else{reflected_color=trace(ctx,hit.point,reflected,recursion-1);}
            color=add(color,mul(reflected_color,hit.texture.reflect));
        }
    }else{
        let horizontal=(direction.x*direction.x+direction.y*direction.y).sqrt();
        let blend=if horizontal>0.0{(direction.z.abs()/horizontal).atan()*0.63661977}else{1.0};
        color=add(mul(SKY_ZENITH,blend),mul(SKY_HORIZON,1.0-blend));
    }
    if color.x>1.0{color.x=1.0;}if color.y>1.0{color.y=1.0;}if color.z>1.0{color.z=1.0;}color
}

#[no_mangle]
pub unsafe extern "C" fn freebench_distray(input:*const i64,input_length:usize,output:*mut u8,output_capacity:usize)->i64{
    if input.is_null()||input_length!=3{return -1;}
    let distribution=*input;let x=*input.add(1);let y=*input.add(2);
    if distribution<1||distribution>5||x<0||x>=WIDTH||y<0||y>=HEIGHT{return -1;}
    if output.is_null()||output_capacity<3{return -2;}
    let mut ctx=Context{distribution:distribution as i32,state:0x52462467};
    let sx=(x-(WIDTH/2)) as f64/WIDTH as f64;let sz=((HEIGHT/2)-y) as f64/HEIGHT as f64;
    let direction=Vec3{x:CAMERA_RIGHT.x*sx+CAMERA_DIR.x+CAMERA_UP.x*sz,y:CAMERA_RIGHT.y*sx+CAMERA_DIR.y+CAMERA_UP.y*sz,z:CAMERA_RIGHT.z*sx+CAMERA_DIR.z+CAMERA_UP.z*sz};
    let mut color=Vec3{x:0.0,y:0.0,z:0.0};
    for _ in 0..ctx.distribution{let offset=distributed(&mut ctx,direction,0.5/WIDTH as f64,0.5/HEIGHT as f64);color=add(color,trace(&mut ctx,CAMERA,add(direction,offset),MAX_REC));}
    color=mul(color,1.0/ctx.distribution as f64);
    *output=(((color.x*255.0) as i32)&0xfe) as u8;*output.add(1)=(((color.y*255.0) as i32)&0xfe) as u8;*output.add(2)=(((color.z*255.0) as i32)&0xfe) as u8;
    3
}
