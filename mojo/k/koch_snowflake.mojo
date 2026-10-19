from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.math import isfinite
comptime P=29
fn f32(x:Float64)->Float32:return Float32(x)
@export("koch_snowflake")
fn koch_snowflake(a:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Float64,ImmutAnyOrigin]() or n<2 or n>20 or not isfinite(a[0]) or not isfinite(a[1]):return -1
    if a[0]<0.0 or a[0]>1.0 or Float64(Int64(a[0]))!=a[0] or a[1]<2.0 or a[1]>8.0 or Float64(Int64(a[1]))!=a[1]:return -1
    let steps=Int(a[0]);let pc=Int(a[1]);if n!=c_size_t(2+2*pc):return -1
    for i in range(2,Int(n)):if not isfinite(a[i]) or a[i]<-1000.0 or a[i]>1000.0:return -1
    let pts=if steps==0 then pc else 4*(pc-1)+1;let need=2*pts
    if o==UnsafePointer[Float64,MutAnyOrigin]() or cap<c_size_t(need):return -2
    var x1=InlineArray[Float32,P]();var y1=InlineArray[Float32,P]();var x2=InlineArray[Float32,P]();var y2=InlineArray[Float32,P]();var cnt=pc
    for i in range(pc):x1[i]=Float32(a[2+2*i]);y1[i]=Float32(a[3+2*i])
    if steps>0:
        var pos=0
        for i in range(pc-1):
            let sx=x1[i];let sy=y1[i];let dx=x1[i+1]-sx;let dy=y1[i+1]-sy;let tx=dx/Float32(3.0);let ty=dy/Float32(3.0)
            let fx=sx+tx;let fy=sy+ty;let rx=Float32(0.49999997)*tx-Float32(0.86602545)*ty;let ry=Float32(0.86602545)*tx+Float32(0.49999997)*ty
            x2[pos]=sx;y2[pos]=sy;pos+=1;x2[pos]=fx;y2[pos]=fy;pos+=1;x2[pos]=fx+rx;y2[pos]=fy+ry;pos+=1
            x2[pos]=sx+dx*Float32(2.0)/Float32(3.0);y2[pos]=sy+dy*Float32(2.0)/Float32(3.0);pos+=1
        x2[pos]=x1[pc-1];y2[pos]=y1[pc-1];cnt=pos+1
        for i in range(cnt):o[2*i]=Float64(x2[i]);o[2*i+1]=Float64(y2[i])
    else:
        for i in range(cnt):o[2*i]=Float64(x1[i]);o[2*i+1]=Float64(y1[i])
    return need
