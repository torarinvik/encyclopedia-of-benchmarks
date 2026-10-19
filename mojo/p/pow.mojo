from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("pow_algorithm")
fn pow_algorithm(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=2 or v[0]<-1000 or v[0]>1000 or v[1]<-8 or v[1]>12:return -1.0e300
    var result=1.0
    for i in range(1,Int(v[1])+1):result*=Float64(v[0])
    return result
