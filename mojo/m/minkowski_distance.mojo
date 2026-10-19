from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.math import exp, log
@export("minkowski_distance")
fn minkowski_distance(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>18 or v[0]<0 or v[0]>8 or v[1]<3 or v[1]>6 or Int(n)!=2+2*Int(v[0]):return -1.0e300
    let count=Int(v[0]);let p=Float64(v[1]);var sum=0.0
    for i in range(count):
        let a=v[2+i];let b=v[2+count+i]
        if a < -100 or a>100 or b < -100 or b>100:return -1.0e300
        let d=Float64(if a>b:a-b else:b-a)
        sum+=exp(p*log(d)) if d>0.0 else 0.0
    return exp(log(sum)/p) if sum>0.0 else 0.0
