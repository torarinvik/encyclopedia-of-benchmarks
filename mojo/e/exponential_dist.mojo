from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("exponential_dist")
fn exponential_dist(values:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Float64:
    if values==UnsafePointer[Int64,ImmutAnyOrigin]() or length!=2:return -1.0e300
    let op=values[0];let rate=values[1]
    if op<0 or op>2 or rate<1 or rate>1000000000:return -1.0e300
    let lambda=Float64(rate)/1000000.0
    if op==1:return 1.0/(lambda*lambda)
    return 1.0/lambda
