from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray
fn gser_put(out:UnsafePointer[UInt8,MutAnyOrigin],pos:Int,x:Float64):
    let bits=bitcast[UInt64](x)
    for b in range(8):out[pos+b]=UInt8((bits>>UInt64(8*b))&255)
@export("geometric_series")
fn geometric_series(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=3 or v[0]<0 or v[0]>16 or v[1]<1 or v[1]>8 or v[2]<1 or v[2]>4:return -1
    let count=Int(v[0]);if cap<c_size_t(count*8) or (count>0 and out==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    var term=Float64(v[1]);let ratio=Float64(v[2])
    for i in range(count):gser_put(out,i*8,term);term*=ratio
    return Int64(count*8)
