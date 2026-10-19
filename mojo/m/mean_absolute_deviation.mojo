from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from std.math import abs

@export("mean_absolute_deviation")
fn mean_absolute_deviation(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>257:return -1.0e300
    let count=v[0];if count<1 or count>256 or n!=c_size_t(count+1):return -1.0e300
    var sum=0.0
    for i in range(Int(count)):
        let x=v[i+1];if x< -1000000 or x>1000000:return -1.0e300
        sum+=Float64(x)
    let mean=sum/Float64(count);var absolute_sum=0.0
    for i in range(Int(count)):
        let d=Float64(v[i+1])-mean;absolute_sum+=abs(d)
    return absolute_sum/Float64(count)
