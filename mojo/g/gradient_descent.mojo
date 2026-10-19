from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray
@export("gradient_descent")
fn gradient_descent(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<5 or n>68:return -1.0e300
    let d=Int(v[0]);let selected=Int(v[1]);let rate=v[2];let iters=v[3]
    if d<1 or d>64 or selected<0 or selected>=d or n!=c_size_t(4+d) or rate<1 or rate>500000 or iters<0 or iters>10000:return -1.0e300
    var x=InlineArray[Float64,64](fill=0.0)
    for i in range(d):if v[4+i]< -10 or v[4+i]>10:return -1.0e300;x[i]=Float64(v[4+i])
    let alpha=Float64(rate)/1000000.0
    for k in range(Int(iters)):
        var grad=InlineArray[Float64,64](fill=0.0)
        for i in range(d):grad[i]=2.0*x[i]
        for i in range(d):x[i]-=alpha*grad[i]
    return x[selected]
