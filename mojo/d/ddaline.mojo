from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
from std.math import floor

fn dda_put(output:UnsafePointer[UInt8,MutAnyOrigin],mut pos:Int,value:Int64):
    let bits=UInt64(value)
    for b in range(8):
        output[pos]=UInt8((bits>>UInt(8*b))&255)
        pos+=1
fn dda_java_round(value:Float64)->Int64:
    return Int64(floor(value+0.5))
@export("ddaline")
fn ddaline(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,output:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length!=4:return -1
    for i in range(4):
        if input[i]<-128 or input[i]>128:return -1
    let dx=input[2]-input[0];let dy=input[3]-input[1]
    var ax=dx;var ay=dy
    if ax<0:ax=-ax
    if ay<0:ay=-ay
    let steps=max(ax,ay)
    if steps>256:return -1
    let points=Int(steps+1);let bytes=points*16
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(bytes):return -2
    if steps==0:
        var pos=0;dda_put(output,pos,input[0]);dda_put(output,pos,input[1]);return 16
    let xinc=Float64(dx)/Float64(steps);let yinc=Float64(dy)/Float64(steps)
    var x=Float64(input[0]);var y=Float64(input[1]);var pos=0
    for _ in range(Int(steps+1)):
        dda_put(output,pos,dda_java_round(x));dda_put(output,pos,dda_java_round(y));x+=xinc;y+=yinc
    return Int64(bytes)
