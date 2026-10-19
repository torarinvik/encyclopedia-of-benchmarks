from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn ema_java_put_f64(out:UnsafePointer[UInt8,MutAnyOrigin],offset:Int,value:Float64):
    let bits=bitcast[UInt64](value)
    for b in range(8):out[offset+b]=UInt8((bits>>UInt(8*b))&255)
fn ema_java_put_i64(out:UnsafePointer[UInt8,MutAnyOrigin],offset:Int,value:Int64):
    let bits=bitcast[UInt64](value)
    for b in range(8):out[offset+b]=UInt8((bits>>UInt(8*b))&255)
@export("exponential_moving_average_java_stream")
fn exponential_moving_average_java_stream(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<2:return -1
    let count=input[1]
    if count<0 or count>256 or length!=c_size_t(2+count) or input[0]< -1000000 or input[0]>1000000:return -1
    for i in range(Int(count)):if input[i+2]< -1000000 or input[i+2]>1000000:return -1
    var mean=Float64(input[0]);var variance:Float64=0.0
    for i in range(Int(count)):
        let value=Float64(input[i+2]);let deviation=value-mean
        mean+=0.25*deviation;variance=0.75*(variance+0.25*deviation*deviation)
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<24:return -2
    ema_java_put_f64(out,0,mean);ema_java_put_f64(out,8,variance);ema_java_put_i64(out,16,count)
    return 24
