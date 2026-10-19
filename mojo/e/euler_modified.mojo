from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn euler_modified_put(out:UnsafePointer[UInt8,MutAnyOrigin],offset:Int,value:Float64):
    let bits=bitcast[UInt64](value)
    for b in range(8):out[offset+b]=UInt8((bits>>UInt(8*b))&255)
@export("euler_modified")
fn euler_modified(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length!=2:return -1
    let steps=input[0];let y0=input[1]
    if steps<1 or steps>8 or y0<1 or y0>4:return -1
    let bytes=Int(steps+1)*8
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(bytes):return -2
    let h=0.25;var x=0.0;var y=Float64(y0);euler_modified_put(out,0,y)
    for i in range(Int(steps)):
        let f1= -2.0*x*y*y;let predictor=y+h*f1
        let f2= -2.0*(x+h)*predictor*predictor
        y=y+(h/2.0)*(f1+f2);x+=h;euler_modified_put(out,(i+1)*8,y)
    return Int64(bytes)
