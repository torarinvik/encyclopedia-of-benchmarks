from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn euler_method_put(out:UnsafePointer[UInt8,MutAnyOrigin],offset:Int,value:Float64):
    let bits=bitcast[UInt64](value)
    for b in range(8):out[offset+b]=UInt8((bits>>UInt(8*b))&255)
@export("euler_method")
fn euler_method(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length!=4:return -1
    let x0=input[0];let y0=input[1];let power=input[2];let steps=input[3]
    if x0< -8 or x0>8 or y0< -8 or y0>8 or power<1 or power>4 or steps<1 or steps>16:return -1
    let bytes=Int(steps+1)*8
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(bytes):return -2
    let h=1.0/Float64(Int64(1)<<Int(power));var x=Float64(x0);var y=Float64(y0)
    euler_method_put(out,0,y)
    for i in range(Int(steps)):
        y=y+h*(x+y);x+=h;euler_method_put(out,(i+1)*8,y)
    return Int64(bytes)
