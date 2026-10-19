from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn ema_standard_put(out:UnsafePointer[UInt8,MutAnyOrigin],offset:Int,value:Float64):
    let bits=bitcast[UInt64](value)
    for b in range(8):out[offset+b]=UInt8((bits>>UInt(8*b))&255)
@export("exponential_moving_average")
fn exponential_moving_average(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<3:return -1
    let window=input[0];let count=input[1]
    if window<2 or window>32 or count<1 or count>256 or length!=c_size_t(count+2):return -1
    for i in range(Int(count)):if input[i+2]< -1000000 or input[i+2]>1000000:return -1
    let bytes=Int(count)*8
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(bytes):return -2
    let alpha=2.0/(1.0+Float64(window));var average:Float64=0.0
    for i in range(Int(count)):
        let price=Float64(input[i+2])
        if i==0:average=price
        elif i<=Int(window):average=(average+price)*0.5
        else:average=(alpha*price)+((1.0-alpha)*average)
        ema_standard_put(out,i*8,average)
    return Int64(bytes)
