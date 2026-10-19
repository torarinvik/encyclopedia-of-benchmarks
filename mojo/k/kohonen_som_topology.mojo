from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.math import exp, isfinite, sqrt
@export("kohonen_som_topology")
fn kohonen_som_topology(a:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Float64,ImmutAnyOrigin]() or n<4 or n>56:return -1
    for i in range(4):if not isfinite(a[i]) or Float64(Int64(a[i]))!=a[i]:return -1
    let m=Int(a[0]);let f=Int(a[1]);let radius=Int(a[2]);let code=Int(a[3])
    if m<1 or m>4 or f<1 or f>3 or radius<0 or radius>8 or code<1 or code>16 or n!=c_size_t(4+f+m*m*f):return -1
    var sample=InlineArray[Float64,3]();var weights=InlineArray[Float64,48]()
    for i in range(f):
        let v=a[4+i];if not isfinite(v) or Float64(Int64(v))!=v or v< -8.0 or v>8.0:return -1
        sample[i]=v
    for i in range(m*m*f):
        let v=a[4+f+i];if not isfinite(v) or Float64(Int64(v))!=v or v< -8.0 or v>8.0:return -1
        weights[i]=v
    var best=0;var best2:Float64=0.0
    for q in range(f):let d=weights[q]-sample[q];best2+=d*d
    var bestdist=sqrt(best2)
    for cell in range(1,m*m):
        var s:Float64=0.0
        for q in range(f):let d=weights[cell*f+q]-sample[q];s+=d*d
        let dist=sqrt(s)
        if dist<bestdist:bestdist=dist;best=cell
    let bx=best//m;let by=best%m;let x0=max(0,bx-radius);let x1=min(m,bx+radius+1);let y0=max(0,by-radius);let y1=min(m,by+radius+1);let alpha=Float64(code)/16.0
    for x in range(x0,x1):
        for y in range(y0,y1):
            let dx=abs(x-bx);let dy=abs(y-by);let d2=Float64(dx*dx+dy*dy);let scale=exp(-d2/(2.0*alpha*alpha))
            for q in range(f):let i=(x*m+y)*f+q;weights[i]+=alpha*scale*(sample[q]-weights[i]);if not isfinite(weights[i]):return -1
    if o==UnsafePointer[Float64,MutAnyOrigin]() or cap<c_size_t(1+m*m*f):return -2
    o[0]=bestdist
    for i in range(m*m*f):o[1+i]=weights[i]
    return 1+m*m*f
