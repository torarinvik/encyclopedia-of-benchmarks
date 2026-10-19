from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray
fn gcus_put(out:UnsafePointer[UInt8,MutAnyOrigin],word:Int,x:Int64):
    let bits=bitcast[UInt64](x)
    for b in range(8):out[word*8+b]=UInt8((bits>>UInt64(8*b))&255)
@export("graph_c_undirected_simple")
fn graph_c_undirected_simple(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or v[0]<1 or v[0]>32 or v[1]<0 or v[1]>2047:return -1
    let count=Int(v[0]);let edges=Int(v[1]);if n!=c_size_t(2+2*edges):return -1
    var mat=InlineArray[UInt8,1024](fill=0)
    for e in range(edges):
        let a=v[2+2*e];let b=v[3+2*e];if a<0 or b<0 or a>=count or b>=count:return -1
        mat[Int(a)*32+Int(b)]=1;mat[Int(b)*32+Int(a)]=1
    let words=count*count
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(words*8):return -2
    for r in range(count):
        for c in range(count):gcus_put(out,r*count+c,Int64(mat[r*32+c]))
    return Int64(words*8)
