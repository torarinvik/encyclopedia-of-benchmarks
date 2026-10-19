from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.math import exp, isfinite

@export("softmax")
fn softmax(values:UnsafePointer[Float64,ImmutAnyOrigin],length:c_size_t,output:UnsafePointer[Float64,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if values==UnsafePointer[Float64,ImmutAnyOrigin]() or length==0 or length>64:return -1
    for i in range(Int(length)):
        if !isfinite(values[i]) or values[i]< -20.0 or values[i]>20.0:return -1
    if output==UnsafePointer[Float64,MutAnyOrigin]() or capacity<length:return -2
    var total=Float64(0.0)
    for i in range(Int(length)):total+=exp(values[i])
    for i in range(Int(length)):output[i]=exp(values[i])/total
    return Int64(length)
