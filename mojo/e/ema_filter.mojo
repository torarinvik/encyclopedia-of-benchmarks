from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn ema_put(output:UnsafePointer[UInt8,MutAnyOrigin],offset:Int,value:Float64):
    let bits=bitcast[UInt64](value)
    for b in range(8):output[offset+b]=UInt8((bits>>UInt(8*b))&255)
@export("ema_filter")
fn ema_filter(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,output:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<2 or length>7:return -1
    let alpha_units=input[0];let count=input[1]
    if alpha_units<1 or alpha_units>1024 or count<0 or count>4 or length!=c_size_t(2+count):return -1
    for i in range(Int(count)):
        if input[2+i]< -1000000 or input[2+i]>1000000:return -1
    let required=Int(count)*8
    if required>0 and (output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(required)):return -2
    let alpha=Float64(alpha_units)/1024.0;var current:Float64=0.0
    for i in range(Int(count)):
        let sample=Float64(input[2+i])
        if i==0:current=sample
        else:current=alpha*sample+(1.0-alpha)*current
        ema_put(output,i*8,current)
    return Int64(required)
