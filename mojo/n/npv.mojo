from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.math import pow
@export("npv")
fn npv(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>66:return -1.0e300
    let count=a[0];let rbp=a[1]
    if count<0 or count>64 or rbp<0 or rbp>1000 or n!=c_size_t(count+2):return -1.0e300
    for i in range(Int(count)):if a[i+2]< -1000000 or a[i+2]>1000000:return -1.0e300
    let rate=Float64(rbp)/10000.0;var total:Float64=0.0
    for t in range(Int(count)):total+=Float64(a[t+2])/pow(1.0+rate,Float64(t))
    return total
