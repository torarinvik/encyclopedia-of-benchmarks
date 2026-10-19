from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("momentum")
fn momentum(v:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Float64,ImmutAnyOrigin]() or n<1 or n>64:return -1
    var x=InlineArray[Float64,64](fill=0.0);var velocity=InlineArray[Float64,64](fill=0.0)
    for i in range(Int(n)):
        if not is_finite(v[i]) or v[i] < -1000000.0 or v[i]>1000000.0:return -1
        x[i]=v[i]
    if out==UnsafePointer[Float64,MutAnyOrigin]() or cap<n:return -2
    for _ in range(100):
        var grad=InlineArray[Float64,64](fill=0.0)
        for i in range(Int(n)):grad[i]=2.0*x[i]
        for i in range(Int(n)):velocity[i]=0.9*velocity[i]+grad[i];x[i]-=0.01*velocity[i]
    for i in range(Int(n)):out[i]=x[i]
    return Int64(n)
