from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
from std.collections import List
from std.math import floor
fn dda_round(x:Float64)->Int64:
    let lower=Int64(floor(x));let fraction=x-Float64(lower)
    if fraction>0.5 or (fraction==0.5 and lower%2!=0):return lower+1
    return lower
fn dda_put(out:UnsafePointer[UInt8,MutAnyOrigin],offset:Int,value:Int64):
    let bits=UInt32(value)
    for b in range(4):out[offset+b]=UInt8((bits>>UInt(8*b))&255)
@export("digital_differential_analyzer_line")
fn digital_differential_analyzer_line(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length!=4:return -1
    for i in range(4):if input[i]< -1000000 or input[i]>1000000:return -1
    let dx=input[2]-input[0];let dy=input[3]-input[1];let ax=dx if dx>=0 else -dx;let ay=dy if dy>=0 else -dy;let steps=ax if ax>ay else ay
    if steps==0 or steps>4096:return -1
    let bytes=Int(steps)*8
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(bytes):return -2
    let xincr=Float64(dx)/Float64(steps);let yincr=Float64(dy)/Float64(steps);var x=Float64(input[0]);var y=Float64(input[1])
    for step in range(Int(steps)):
        x+=xincr;y+=yincr;dda_put(out,step*8,dda_round(x));dda_put(out,step*8+4,dda_round(y))
    return Int64(bytes)
