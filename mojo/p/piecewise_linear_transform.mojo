from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("piecewise_linear_transform")
fn piecewise_linear_transform(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n==0 or n>256:return -1
    for i in range(Int(n)):if v[i]<0 or v[i]>255:return -1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<n:return -2
    for i in range(Int(n)):
        let x=Float64(v[i]);var y=0.0
        if v[i]<=100:y=0.5*x
        elif v[i]<=180:y=(150.0/80.0)*(x-100.0)+50.0
        else:y=(55.0/75.0)*(x-180.0)+200.0
        o[i]=UInt8(Int(y))
    return Int64(n)
