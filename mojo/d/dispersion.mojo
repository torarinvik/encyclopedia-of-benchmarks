from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
from std.collections import List
from std.math import sqrt
fn dispersion_put(out:UnsafePointer[UInt8,MutAnyOrigin],offset:Int,value:Float64):
    let bits=bitcast[UInt64](value)
    for b in range(8):out[offset+b]=UInt8((bits>>UInt(8*b))&255)
@export("dispersion")
fn dispersion(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length==0 or length>128:return -1
    var sum:Float64=0.0
    for i in range(Int(length)):
        if input[i]< -10000 or input[i]>10000:return -1
        sum+=Float64(input[i])
    let mean=sum/Float64(length);var squared:Float64=0.0
    for i in range(Int(length)):let delta=Float64(input[i])-mean;squared+=delta*delta
    let variance=squared/Float64(length);let deviation=sqrt(variance)
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<16:return -2
    dispersion_put(out,0,variance);dispersion_put(out,8,deviation)
    return 16
