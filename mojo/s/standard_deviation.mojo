from std.ffi import c_size_t
from std.math import isfinite, sqrt
from std.memory import ImmutAnyOrigin, UnsafePointer
comptime BAD:Float64= -1.0e300
@export("standard_deviation")
fn standard_deviation(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n==0 or n>64:return BAD
    var sum=0.0
    for i in range(Int(n)):
        if v[i]< -1000000 or v[i]>1000000:return BAD
        sum+=Float64(v[i])
    let avg=sum/Float64(n);var ss=0.0
    for i in range(Int(n)):let d=Float64(v[i])-avg;ss+=d*d
    return sqrt(ss/Float64(n))
