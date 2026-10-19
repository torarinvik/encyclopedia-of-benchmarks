from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
from std.collections import InlineArray

fn mp_store(out:UnsafePointer[UInt8,MutAnyOrigin],pos:Int,x:Float64):
    let bits=bitcast[UInt64](x)
    for b in range(8):out[pos+b]=UInt8((bits>>UInt64(8*b))&255)

@export("max_pooling")
fn max_pooling(v:UnsafePointer[Int32,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int32,ImmutAnyOrigin]() or n<3 or n>259:return -1
    let d=Int(v[0]);let size=Int(v[1]);let stride=Int(v[2])
    if d<1 or d>16 or size<1 or size>d or stride<1 or stride>16 or n!=c_size_t(3+d*d):return -1
    for i in range(d*d):if v[3+i]< -1000000 or v[3+i]>1000000:return -1
    let side=(d-size)/stride+1;let count=side*side;let bytes=count*8
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    var result=InlineArray[Float64,256](fill=0.0);var pos=0
    for r in range(side):for c in range(side):
        let sr=r*stride;let sc=c*stride;var maximum=v[3+sr*d+sc]
        for wr in range(size):for wc in range(size):
            let value=v[3+(sr+wr)*d+sc+wc];if value>maximum:maximum=value
        result[pos]=Float64(maximum);pos+=1
    for i in range(count):mp_store(out,i*8,result[i])
    return Int64(bytes)
