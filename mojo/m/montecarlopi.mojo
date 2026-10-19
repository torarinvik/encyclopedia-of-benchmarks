from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("montecarlopi")
fn montecarlopi(v:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Float64,ImmutAnyOrigin]() or n<3 or n>130:return -1
    for i in range(Int(n)):if not is_finite(v[i]):return -1
    let count=Int(v[0]);if v[0]!=Float64(count) or count<1 or count>64 or Int(n)!=1+2*count:return -1
    var inside=0
    for i in range(count):
        let x=v[1+2*i];let y=v[2+2*i]
        if (x!=0.0 and x!=0.25 and x!=0.5 and x!=0.75) or (y!=0.0 and y!=0.25 and y!=0.5 and y!=0.75):return -1
        if x*x+y*y<=1.0:inside+=1
    let estimate=(Float64(inside)/Float64(count))*4.0
    if o==UnsafePointer[Float64,MutAnyOrigin]() or cap<1:return -2
    o[0]=estimate;return 1
