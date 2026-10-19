from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
from std.math import sqrt

fn data_norm_put(output:UnsafePointer[UInt8,MutAnyOrigin],offset:Int,value:Float64):
    let bits=bitcast[UInt64](value)
    for b in range(8):output[offset+b]=UInt8((bits>>UInt(8*b))&255)
@export("data_normalization_standardization")
fn data_normalization_standardization(values:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,output:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if values==UnsafePointer[Int64,ImmutAnyOrigin]() or length<4 or length>130:return -1
    let mode=values[0];let n=values[1]
    if (mode!=0 and mode!=1) or n<2 or n>128 or length!=c_size_t(n+2):return -1
    var minimum=values[2];var maximum=values[2];var sum:Float64=0.0
    for i in range(Int(n)):
        let v=values[i+2]
        if v< -100000 or v>100000:return -1
        if v<minimum:minimum=v
        if v>maximum:maximum=v
        sum+=Float64(v)
    if minimum==maximum:return -1
    let bytes=Int(n)*8
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(bytes):return -2
    if mode==0:
        let span=Float64(maximum-minimum)
        for i in range(Int(n)):data_norm_put(output,i*8,(Float64(values[i+2])-Float64(minimum))/span)
    else:
        let mean=sum/Float64(n);var sq:Float64=0.0
        for i in range(Int(n)):
            let diff=Float64(values[i+2])-mean;sq+=diff*diff
        let sd=sqrt(sq/Float64(n-1))
        for i in range(Int(n)):data_norm_put(output,i*8,(Float64(values[i+2])-mean)/sd)
    return Int64(bytes)
