from std.ffi import c_size_t
from std.math import cos, isfinite, sin
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
comptime PI:Float64=3.14159265358979323846264338327950288
@export("spirograph")
fn spirograph(v:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Float64,ImmutAnyOrigin]() or n<1 or n>5 or n!=4:return -1
    if not isfinite(v[0]) or v[0]<1 or v[0]>32 or v[0]!=Float64(Int(v[0])):return -1
    if not isfinite(v[1]) or v[1]<0 or v[1]>1 or not isfinite(v[2]) or v[2]<0.25 or v[2]>0.75 or not isfinite(v[3]) or v[3]<0 or v[3]>10:return -1
    let points=Int(v[0]);let delta=v[3]*2.0*PI/Float64(points);let k1=1.0-v[2]
    var res=InlineArray[Float64,64](fill=0.0)
    for i in range(points):
        let t=Float64(i)*delta;let ia=k1*t/v[2]
        let x=k1*cos(t)+v[1]*v[2]*cos(ia);let y=k1*sin(t)-v[1]*v[2]*sin(ia)
        if not isfinite(x) or not isfinite(y):return -1
        res[2*i]=x;res[2*i+1]=y
    if o==UnsafePointer[Float64,MutAnyOrigin]() or cap<c_size_t(points*2):return -2
    for i in range(points*2):o[i]=res[i]
    return Int64(points*2)
