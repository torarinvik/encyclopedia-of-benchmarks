# Independent bounded FreeBench/distray profile. Ray tracer attributed to
# Marcus Geelnard; benchmarkification to Peter Rundberg (biff@ce.chalmers.se).
# The pinned upstream source has no explicit license grant.
from std.ffi import c_size_t
from std.math import sqrt, atan, abs
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias DV = (Float64,Float64,Float64)

fn dv_add(a: DV,b: DV) -> DV: return (a[0]+b[0],a[1]+b[1],a[2]+b[2])
fn dv_sub(a: DV,b: DV) -> DV: return (a[0]-b[0],a[1]-b[1],a[2]-b[2])
fn dv_scale(a: DV,s: Float64) -> DV: return (a[0]*s,a[1]*s,a[2]*s)
fn dv_dot(a: DV,b: DV) -> Float64: return a[0]*b[0]+a[1]*b[1]+a[2]*b[2]
fn dv_length(a: DV) -> Float64: return sqrt(dv_dot(a,a))

fn dv_jitter(mut state: Int64) -> Float64:
    state=(1103515245*state+12345) & 0x7fffffff
    return 1.0-Float64(state)/Float64(0x3fffffff)

fn dv_distributed(mut state: Int64, normal: DV, sa: Float64, sb: Float64) -> DV:
    var a: DV=(0.0,0.0,0.0); var b: DV=(0.0,0.0,0.0)
    if abs(normal[2])>0.00001:
        a=(normal[1]*normal[2],-normal[0]*normal[2],0.0)
        b=(a[1]*normal[2],-a[0]*normal[2],a[0]*normal[1]-a[1]*normal[0])
    else:
        a=(normal[1],-normal[0],0.0); b=(0.0,0.0,1.0)
    let size=dv_length(normal)
    let first=sa*(size/dv_length(a))*dv_jitter(state)
    let second=sb*(size/dv_length(b))*dv_jitter(state)
    return dv_add(dv_scale(a,first),dv_scale(b,second))

# Return distance, point, normal, color, diffuse, reflection, roughness.
fn dv_intersection(origin: DV, direction: DV) -> (Float64,DV,DV,DV,Float64,Float64,Float64):
    var t=Float64(-1); var point: DV=(0.0,0.0,0.0); var normal: DV=(0.0,0.0,0.0)
    var color: DV=(0.0,0.0,0.0); var diffuse=Float64(0); var reflect=Float64(0); var rough=Float64(0)
    if abs(direction[2])>0.00001:
        let hit = -origin[2]/direction[2]
        if hit>0.00001 and hit<100000.0:
            t=hit; point=dv_add(origin,dv_scale(direction,hit)); normal=(0.0,0.0,1.0)
            let tile=(Int(point[0]+50000.0)+Int(point[1]+50000.0)) & 1
            if tile==0: color=(0.0,0.1,0.5); rough=0.02
            else: color=(0.6,1.0,0.5); rough=0.01
            diffuse=0.8; reflect=0.44
    for index in range(4):
        var center: DV=(0.0,4.0,1.0); var radius=Float64(1)
        var sphere_color: DV=(1.0,0.4,0.0); var d=Float64(0.4); var r=Float64(0.8); var q=Float64(0.02)
        if index==1:
            center=(-1.0,3.0,0.4); radius=0.4; sphere_color=(0.5,0.3,1.0); d=0.5; r=0.9; q=0.01
        elif index==2:
            center=(-0.3,1.0,0.4); radius=0.4; sphere_color=(0.1,0.95,0.2); d=0.6; r=0.8; q=0.01
        elif index==3:
            center=(1.0,2.0,0.4); radius=0.4; sphere_color=(0.86,0.83,0.0); d=0.7; r=0.6; q=0.01
        let relative=dv_sub(center,origin)
        let inverse=1.0/dv_dot(direction,direction)
        let projection=dv_dot(relative,direction)*inverse
        let discriminant=(radius*radius-dv_dot(relative,relative))*inverse+projection*projection
        if discriminant>0.0:
            let root=sqrt(discriminant)
            var candidate=projection-root
            if candidate<0.00001: candidate=projection+root
            if candidate>0.00001 and (t<0.0 or candidate<t):
                t=candidate
                let local=dv_scale(direction,candidate)
                point=dv_add(origin,local); normal=dv_sub(local,relative)
                color=sphere_color; diffuse=d; reflect=r; rough=q
    return (t,point,normal,color,diffuse,reflect,rough)

fn dv_trace(mut state: Int64, distribution: Int, origin: DV, direction: DV, recursion: Int) -> DV:
    if recursion<=0: return (0.0,0.0,0.0)
    let hit=dv_intersection(origin,direction)
    var color: DV=(0.0,0.0,0.0)
    let distributed=(6-recursion)<3
    if hit[0]>0.00001:
        let light=dv_sub((-3.0,1.0,5.0),hit[1])
        let light_dot=dv_dot(light,hit[2])
        var intensity=Float64(0)
        if light_dot>0.0:
            var visible=0
            if distributed:
                let spread=0.4/dv_length(light)
                for _ in range(distribution):
                    let offset=dv_distributed(state,light,spread,spread)
                    let shadow=dv_intersection(hit[1],dv_add(light,offset))
                    if shadow[0]<0.00001 or shadow[0]>1.0: visible+=1
            else:
                let shadow=dv_intersection(hit[1],light)
                if shadow[0]<0.00001 or shadow[0]>1.0: visible=distribution
            if visible>0:
                intensity=light_dot/sqrt(dv_dot(hit[2],hit[2])*dv_dot(light,light))*hit[4]*Float64(visible)/Float64(distribution)
        color=dv_scale(hit[3],0.3+intensity)
        if hit[5]>0.00001:
            let reflected=dv_add(direction,dv_scale(hit[2],-2.0*dv_dot(direction,hit[2])/dv_dot(hit[2],hit[2])))
            var reflected_color: DV=(0.0,0.0,0.0)
            if distributed and hit[6]>0.00001:
                for _ in range(distribution):
                    let offset=dv_distributed(state,reflected,hit[6],hit[6])
                    reflected_color=dv_add(reflected_color,dv_trace(state,distribution,hit[1],dv_add(reflected,offset),recursion-1))
                reflected_color=dv_scale(reflected_color,1.0/Float64(distribution))
            else: reflected_color=dv_trace(state,distribution,hit[1],reflected,recursion-1)
            color=dv_add(color,dv_scale(reflected_color,hit[5]))
    else:
        let horizontal=sqrt(direction[0]*direction[0]+direction[1]*direction[1])
        let blend=atan(abs(direction[2])/horizontal)*0.63661977 if horizontal>0.0 else 1.0
        color=dv_add(dv_scale((0.0,0.0,0.2),blend),dv_scale((0.5,0.3,0.7),1.0-blend))
    return (min(color[0],1.0),min(color[1],1.0),min(color[2],1.0))

@export("freebench_distray")
fn freebench_distray(input: UnsafePointer[Int64,ImmutAnyOrigin], length: c_size_t,
                     output: UnsafePointer[UInt8,MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length!=3: return -1
    if input[0]<1 or input[0]>5 or input[1]<0 or input[1]>=640 or input[2]<0 or input[2]>=480: return -1
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<3: return -2
    let distribution=Int(input[0])
    let sx=Float64(input[1]-320)/640.0; let sz=Float64(240-input[2])/480.0
    let direction: DV=(3.0*sx-1.0,sx+3.0,2.3717*sz)
    var state=Int64(0x52462467)
    var color: DV=(0.0,0.0,0.0)
    for _ in range(distribution):
        let offset=dv_distributed(state,direction,0.5/640.0,0.5/480.0)
        color=dv_add(color,dv_trace(state,distribution,(1.5,-1.4,1.2),dv_add(direction,offset),6))
    color=dv_scale(color,1.0/Float64(distribution))
    output[0]=UInt8(Int(color[0]*255.0) & 254)
    output[1]=UInt8(Int(color[1]*255.0) & 254)
    output[2]=UInt8(Int(color[2]*255.0) & 254)
    return 3
