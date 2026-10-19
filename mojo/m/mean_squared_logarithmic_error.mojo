from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from std.math import log1p

@export("mean_squared_logarithmic_error")
fn mean_squared_logarithmic_error(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1:return -1.0e300
    let count=v[0];if count<1 or count>64 or n!=c_size_t(1+2*count):return -1.0e300
    for i in range(Int(2*count)):if v[i+1]< -999999 or v[i+1]>1000000:return -1.0e300
    var total=0.0
    for i in range(Int(count)):
        let t=Float64(v[i+1])/1000000.0;let p=Float64(v[Int(count)+i+1])/1000000.0
        let diff=log1p(t)-log1p(p);total+=diff*diff
    return total/Float64(count)
