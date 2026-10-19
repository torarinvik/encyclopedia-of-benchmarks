from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("line_sweep")
fn line_sweep(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>17:return -1.0e300
    let count=v[0]
    if count<0 or count>8 or n!=c_size_t(1+2*count):return -1.0e300
    if count==0:return 0.0
    var events=InlineArray[Int64,22](fill=0)
    for i in range(Int(count)):
        let s=v[1+2*i];let e=v[2+2*i]
        if s<0 or e<s or e>20:return -1.0e300
        events[s]+=1;events[e+1]-=1
    var active:Int64=0;var best:Int64=0
    for i in range(22):active+=events[i];best=max(best,active)
    return if best>1:1.0 else:0.0
