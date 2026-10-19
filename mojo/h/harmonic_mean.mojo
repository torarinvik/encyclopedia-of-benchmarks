from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("harmonic_mean")
fn harmonic_mean(values:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Float64:
    if values==UnsafePointer[Int64,ImmutAnyOrigin]() or length<1 or length>64:return -1.0e300
    var sum:Float64=0.0
    for i in range(Int(length)):
        if values[i]<1 or values[i]>1000:return -1.0e300
        sum+=1.0/Float64(values[i])
    return Float64(length)/sum
