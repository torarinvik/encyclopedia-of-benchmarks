from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime CMSE_MAX_N = 4
comptime CMSE_MAX_LENGTH = 14

@fieldwise_init
struct CmsePoint(Copyable):
    var x: Int64
    var y: Int64
    var z: Int64

@fieldwise_init
struct CmseTriangle(Copyable):
    var a: Int
    var b: Int
    var c: Int

@fieldwise_init
struct CmseSlope(Copyable):
    var num: Int64
    var den: Int64

fn cmse_orient(p: InlineArray[CmsePoint, CMSE_MAX_N], a: Int, b: Int, c: Int) -> Int64:
    (p[b].x-p[a].x)*(p[c].y-p[a].y)-(p[b].y-p[a].y)*(p[c].x-p[a].x)

fn cmse_slope(p: InlineArray[CmsePoint, CMSE_MAX_N], t: CmseTriangle) -> CmseSlope:
    let a=p[t.a]; let b=p[t.b]; let c=p[t.c]
    let dx1=b.x-a.x; let dy1=b.y-a.y; let dz1=b.z-a.z
    let dx2=c.x-a.x; let dy2=c.y-a.y; let dz2=c.z-a.z
    let det=dx1*dy2-dx2*dy1; let gx=dz1*dy2-dz2*dy1; let gy=dx1*dz2-dz1*dx2
    CmseSlope(gx*gx+gy*gy,det*det)

fn cmse_cmp(a: CmseSlope,b: CmseSlope) -> Int:
    let x=a.num*b.den; let y=b.num*a.den
    if x>y: return 1
    if x<y: return -1
    0

fn cmse_max(p: InlineArray[CmsePoint, CMSE_MAX_N],a: CmseTriangle,b: CmseTriangle) -> CmseSlope:
    let x=cmse_slope(p,a);let y=cmse_slope(p,b)
    if cmse_cmp(x,y)>=0: x else: y

fn cmse_anchor(p: InlineArray[CmsePoint, CMSE_MAX_N],t: CmseTriangle,q: Int) -> Bool:
    let a=p[t.a];let b=p[t.b];let c=p[t.c]
    let dx1=b.x-a.x;let dy1=b.y-a.y;let dz1=b.z-a.z;let dx2=c.x-a.x;let dy2=c.y-a.y;let dz2=c.z-a.z
    let det=dx1*dy2-dx2*dy1;let gx=dz1*dy2-dz2*dy1;let gy=dx1*dz2-dz1*dx2
    if gx==0 and gy==0: return False
    var other=InlineArray[Int,2](fill=0);var used=0
    for v in InlineArray[Int,3](t.a,t.b,t.c):
        if v!=q: other[used]=v;used+=1
    let sign:Int64=1 if det>0 else -1
    let dx=-gx*sign;let dy=-gy*sign
    let ux=p[other[0]].x-p[q].x;let uy=p[other[0]].y-p[q].y
    let vx=p[other[1]].x-p[q].x;let vy=p[other[1]].y-p[q].y
    let turn=ux*vy-uy*vx;let side:Int64=1 if turn>0 else -1
    side*(ux*dy-uy*dx)>=0 and side*(dx*vy-dy*vx)>=0

fn cmse_crosses(p: InlineArray[CmsePoint, CMSE_MAX_N],a:Int,b:Int,c:Int,d:Int) -> Bool:
    cmse_orient(p,a,b,c)*cmse_orient(p,a,b,d)<0 and cmse_orient(p,c,d,a)*cmse_orient(p,c,d,b)<0

fn cmse_volume(p: InlineArray[CmsePoint, CMSE_MAX_N]) -> Int64:
    let ax=p[1].x-p[0].x;let ay=p[1].y-p[0].y;let az=p[1].z-p[0].z
    let bx=p[2].x-p[0].x;let by=p[2].y-p[0].y;let bz=p[2].z-p[0].z
    let cx=p[3].x-p[0].x;let cy=p[3].y-p[0].y;let cz=p[3].z-p[0].z
    ax*(by*cz-bz*cy)-ay*(bx*cz-bz*cx)+az*(bx*cy-by*cx)

fn cmse_rank(p: InlineArray[CmsePoint, CMSE_MAX_N],n:Int,target:CmseSlope) -> Int64:
    var all=InlineArray[CmseSlope,4](fill=CmseSlope(0,1));var count=0
    for a in range(n):
        for b in range(a+1,n):
            for c in range(b+1,n): all[count]=cmse_slope(p,CmseTriangle(a,b,c));count+=1
    var distinct=0
    for i in range(count):
        if cmse_cmp(all[i],target)<0:
            var seen=False
            for j in range(i):
                if cmse_cmp(all[j],all[i])==0: seen=True
            if not seen: distinct+=1
    Int64(distinct+1)

fn cmse_impl(input: UnsafePointer[Int64, ImmutAnyOrigin],length:Int) -> Int64:
    if length<1 or length>CMSE_MAX_LENGTH:return -1
    if input[0]<3 or input[0]>4:return -1
    let n=Int(input[0]);if length!=1+3*n:return -1
    var p=InlineArray[CmsePoint,CMSE_MAX_N](fill=CmsePoint(0,0,0))
    for i in range(n):
        p[i]=CmsePoint(input[1+3*i],input[2+3*i],input[3+3*i])
        if p[i].x < -8 or p[i].x>8 or p[i].y < -8 or p[i].y>8 or p[i].z < -8 or p[i].z>8:return -1
    var area:Int64=0
    for i in range(n):
        let j=(i+1)%n;area+=p[i].x*p[j].y-p[i].y*p[j].x
    if area==0:return -1
    let sign:Int64=1 if area>0 else -1
    for a in range(n):
        for b in range(a+1,n):
            for c in range(b+1,n):
                if cmse_orient(p,a,b,c)==0:return -1
    for e in range(n):
        let j=(e+1)%n
        for k in range(n):
            if k!=e and k!=j and sign*cmse_orient(p,e,j,k)<=0:return -1
    if n==4 and cmse_volume(p)==0:return -1
    let fan=InlineArray[CmseTriangle,2](CmseTriangle(0,1,2),CmseTriangle(0,2,3))
    var worst=if n==3:cmse_slope(p,fan[0]) else:cmse_max(p,fan[0],fan[1])
    if n==4:
        var done=False
        for ti in range(2):
            if done:break
            let t=fan[ti]
            if cmse_cmp(cmse_slope(p,t),worst)!=0:continue
            let v=InlineArray[Int,3](t.a,t.b,t.c)
            for k in range(3):
                if done:break
                let q=v[k];if not cmse_anchor(p,t,q):continue
                var o=InlineArray[Int,2](fill=0);var used=0;var s=4
                for j in range(3):
                    if j!=k:o[used]=v[j];used+=1
                for j in range(4):
                    if j!=v[0] and j!=v[1] and j!=v[2]:s=j
                if not cmse_crosses(p,q,s,o[0],o[1]):continue
                let candidate=cmse_max(p,CmseTriangle(q,s,o[0]),CmseTriangle(q,s,o[1]))
                if cmse_cmp(candidate,worst)<0:worst=candidate;done=True
    cmse_rank(p,n,worst)

@export("convex_polygon_minimax_slope_edge_insertion")
fn convex_polygon_minimax_slope_edge_insertion(input: UnsafePointer[Int64, ImmutAnyOrigin],length:c_size_t) abi("C") -> Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length>c_size_t(CMSE_MAX_LENGTH):return -1
    cmse_impl(input,Int(length))
