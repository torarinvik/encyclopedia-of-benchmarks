from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.math import sqrt

@export("euclidean_distance")
fn euclidean_distance(values:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Float64:
    if values==UnsafePointer[Int64,ImmutAnyOrigin]() or length<1 or length>257:return -1.0e300
    let n=values[0]
    if n<0 or n>128 or length!=c_size_t(1+2*n):return -1.0e300
    var sum:Float64=0.0
    for i in range(Int(n)):
        let a=values[1+i];let b=values[1+Int(n)+i]
        if a< -1000000 or a>1000000 or b< -1000000 or b>1000000:return -1.0e300
        let delta=Float64(a-b);sum+=delta*delta
    return sqrt(sum)
