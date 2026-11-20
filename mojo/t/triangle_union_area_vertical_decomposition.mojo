# Clean-room exact vertical-stripe profile; see benchmarks/t/.../README.md.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_T = 3
comptime MAX_S = 9
comptime MAX_E = 45

@fieldwise_init
struct TriUdRat(Copyable):
    var n: Int64
    var d: Int64

@fieldwise_init
struct TriUdSeg(Copyable):
    var x0: Int64
    var y0: Int64
    var x1: Int64
    var y1: Int64
    var id: Int

@fieldwise_init
struct TriUdInterval(Copyable):
    var lo: TriUdRat
    var hi: TriUdRat
    var low: TriUdSeg
    var high: TriUdSeg
    var low_id: Int
    var high_id: Int

fn tri_ud_abs(x: Int64) -> Int64:
    if x < 0: -x else: x

fn tri_ud_gcd(x: Int64, y: Int64) -> Int64:
    var a=tri_ud_abs(x)
    var b=tri_ud_abs(y)
    while b != 0:
        let rem=a%b
        a=b
        b=rem
    if a == 0: 1 else: a

fn tri_ud_rat(n0: Int64, d0: Int64) -> TriUdRat:
    var n=n0
    var d=d0
    if d < 0:
        n = -n
        d = -d
    let g=tri_ud_gcd(n,d)
    TriUdRat(n/g,d/g)

fn tri_ud_add(a: TriUdRat, b: TriUdRat) -> TriUdRat:
    tri_ud_rat(a.n*b.d+b.n*a.d,a.d*b.d)

fn tri_ud_sub(a: TriUdRat, b: TriUdRat) -> TriUdRat:
    tri_ud_rat(a.n*b.d-b.n*a.d,a.d*b.d)

fn tri_ud_mul(a: TriUdRat, b: TriUdRat) -> TriUdRat:
    tri_ud_rat(a.n*b.n,a.d*b.d)

fn tri_ud_div(a: TriUdRat, b: TriUdRat) -> TriUdRat:
    tri_ud_rat(a.n*b.d,a.d*b.n)

fn tri_ud_cmp(a: TriUdRat, b: TriUdRat) -> Int:
    let x=a.n*b.d
    let y=b.n*a.d
    if x < y: -1
    elif x > y: 1
    else: 0

fn tri_ud_cross(ax: Int64, ay: Int64, bx: Int64, by: Int64) -> Int64:
    ax*by-ay*bx

fn tri_ud_orient(ax: Int64, ay: Int64, bx: Int64, by: Int64, cx: Int64, cy: Int64) -> Int64:
    tri_ud_cross(bx-ax,by-ay,cx-ax,cy-ay)

fn tri_ud_y_at(s: TriUdSeg, x: TriUdRat) -> TriUdRat:
    tri_ud_add(tri_ud_rat(s.y0,1),tri_ud_mul(tri_ud_rat(s.y1-s.y0,s.x1-s.x0),tri_ud_sub(x,tri_ud_rat(s.x0,1))))

fn tri_ud_intersection(a: TriUdSeg, b: TriUdSeg) -> (Bool, TriUdRat):
    let rx=a.x1-a.x0
    let ry=a.y1-a.y0
    let sx=b.x1-b.x0
    let sy=b.y1-b.y0
    let den=tri_ud_cross(rx,ry,sx,sy)
    if den == 0: return (False,tri_ud_rat(0,1))
    let qx=b.x0-a.x0
    let qy=b.y0-a.y0
    let t=tri_ud_rat(tri_ud_cross(qx,qy,sx,sy),den)
    let u=tri_ud_rat(tri_ud_cross(qx,qy,rx,ry),den)
    if tri_ud_cmp(t,tri_ud_rat(0,1)) < 0 or tri_ud_cmp(t,tri_ud_rat(1,1)) > 0 or tri_ud_cmp(u,tri_ud_rat(0,1)) < 0 or tri_ud_cmp(u,tri_ud_rat(1,1)) > 0:
        return (False,tri_ud_rat(0,1))
    (True,tri_ud_add(tri_ud_rat(a.x0,1),tri_ud_mul(t,tri_ud_rat(rx,1))))

fn tri_ud_push_event(events: UnsafePointer[TriUdRat, MutAnyOrigin], count: Int, value: TriUdRat) -> Int:
    for i in range(count):
        if tri_ud_cmp(events[i],value) == 0: return count
    events[count]=value
    count+1

fn tri_ud_less_interval(a: TriUdInterval, b: TriUdInterval) -> Bool:
    let c=tri_ud_cmp(a.lo,b.lo)
    if c != 0: return c < 0
    if a.low_id != b.low_id: return a.low_id < b.low_id
    let h=tri_ud_cmp(a.hi,b.hi)
    if h != 0: return h < 0
    a.high_id < b.high_id

fn tri_ud_integrate(area: UnsafePointer[TriUdRat, MutAnyOrigin], low: TriUdSeg, high: TriUdSeg, xl: TriUdRat, xr: TriUdRat):
    let h0=tri_ud_sub(tri_ud_y_at(high,xl),tri_ud_y_at(low,xl))
    let h1=tri_ud_sub(tri_ud_y_at(high,xr),tri_ud_y_at(low,xr))
    area[0]=tri_ud_add(area[0],tri_ud_mul(tri_ud_sub(xr,xl),tri_ud_div(tri_ud_add(h0,h1),tri_ud_rat(2,1))))

fn tri_ud_store(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits=bitcast[UInt64](value)
    for byte in range(8):
        output[offset+byte]=UInt8((bits>>(byte*8))&UInt64(255))

@export("triangle_union_area_vertical_decomposition")
fn triangle_union_area_vertical_decomposition(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > c_size_t(20): return -1
    let nv=input[0]
    if nv < 1 or nv > 3 or length != c_size_t(1+6*nv): return -1
    let n=Int(nv)
    var px=InlineArray[Int64,9](fill=0)
    var py=InlineArray[Int64,9](fill=0)
    for t in range(n):
        for j in range(3):
            let x=input[1+6*t+2*j]
            let y=input[2+6*t+2*j]
            if x < -1 or x > 1 or y < -1 or y > 1: return -1
            px[3*t+j]=x
            py[3*t+j]=y
        if (px[3*t]==px[3*t+1] and py[3*t]==py[3*t+1]) or (px[3*t]==px[3*t+2] and py[3*t]==py[3*t+2]) or (px[3*t+1]==px[3*t+2] and py[3*t+1]==py[3*t+2]) or tri_ud_orient(px[3*t],py[3*t],px[3*t+1],py[3*t+1],px[3*t+2],py[3*t+2])==0: return -1
    var seg=InlineArray[TriUdSeg,MAX_S](fill=TriUdSeg(0,0,0,0,0))
    var events=InlineArray[TriUdRat,MAX_E](fill=tri_ud_rat(0,1))
    var ns=0
    var ne=0
    for t in range(n):
        for j in range(3):
            let k=(j+1)%3
            seg[ns]=TriUdSeg(px[3*t+j],py[3*t+j],px[3*t+k],py[3*t+k],3*t+j)
            ne=tri_ud_push_event(events.unsafe_ptr(),ne,tri_ud_rat(px[3*t+j],1))
            ns+=1
    for i in range(ns):
        for j in range(i+1,ns):
            let (valid,x)=tri_ud_intersection(seg[i],seg[j])
            if valid: ne=tri_ud_push_event(events.unsafe_ptr(),ne,x)
    for i in range(1,ne):
        let value=events[i]
        var j=i
        while j>0 and tri_ud_cmp(value,events[j-1])<0:
            events[j]=events[j-1]
            j-=1
        events[j]=value
    var area=InlineArray[TriUdRat,1](tri_ud_rat(0,1))
    for e in range(max(ne-1,0)):
        let xl=events[e]
        let xr=events[e+1]
        if tri_ud_cmp(xl,xr)>=0: continue
        let xm=tri_ud_div(tri_ud_add(xl,xr),tri_ud_rat(2,1))
        var intervals=InlineArray[TriUdInterval,MAX_T](fill=TriUdInterval(tri_ud_rat(0,1),tri_ud_rat(0,1),TriUdSeg(0,0,0,0,0),TriUdSeg(0,0,0,0,0),0,0))
        var ni=0
        for t in range(n):
            var cross_seg=InlineArray[TriUdSeg,3](fill=TriUdSeg(0,0,0,0,0))
            var ys=InlineArray[TriUdRat,3](fill=tri_ud_rat(0,1))
            var count=0
            for j in range(3):
                let s=seg[3*t+j]
                let lo_x=min(s.x0,s.x1)
                let hi_x=max(s.x0,s.x1)
                if s.x0!=s.x1 and tri_ud_cmp(xm,tri_ud_rat(lo_x,1))>0 and tri_ud_cmp(xm,tri_ud_rat(hi_x,1))<0:
                    cross_seg[count]=s
                    ys[count]=tri_ud_y_at(s,xm)
                    count+=1
            if count==0: continue
            if count!=2: return -1
            let swap=tri_ud_cmp(ys[0],ys[1])>0 or (tri_ud_cmp(ys[0],ys[1])==0 and cross_seg[0].id>cross_seg[1].id)
            if swap: intervals[ni]=TriUdInterval(ys[1],ys[0],cross_seg[1],cross_seg[0],cross_seg[1].id,cross_seg[0].id)
            else: intervals[ni]=TriUdInterval(ys[0],ys[1],cross_seg[0],cross_seg[1],cross_seg[0].id,cross_seg[1].id)
            ni+=1
        for i in range(1,ni):
            let value=intervals[i]
            var j=i
            while j>0 and tri_ud_less_interval(value,intervals[j-1]):
                intervals[j]=intervals[j-1]
                j-=1
            intervals[j]=value
        var have=False
        var low=TriUdSeg(0,0,0,0,0)
        var high=TriUdSeg(0,0,0,0,0)
        var top=tri_ud_rat(0,1)
        var high_id=0
        for i in range(ni):
            let item=intervals[i]
            if not have:
                low=item.low
                high=item.high
                top=item.hi
                high_id=item.high_id
                have=True
            elif tri_ud_cmp(item.lo,top)<=0:
                let c=tri_ud_cmp(item.hi,top)
                if c>0 or (c==0 and item.high_id<high_id):
                    high=item.high
                    top=item.hi
                    high_id=item.high_id
            else:
                tri_ud_integrate(area.unsafe_ptr(),low,high,xl,xr)
                low=item.low
                high=item.high
                top=item.hi
                high_id=item.high_id
        if have: tri_ud_integrate(area.unsafe_ptr(),low,high,xl,xr)
    let result=area[0]
    if result.n<0 or result.d<=0 or result.n>11289600 or result.d>2822400: return -1
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<16: return -2
    tri_ud_store(output,0,result.n)
    tri_ud_store(output,8,result.d)
    return 16
