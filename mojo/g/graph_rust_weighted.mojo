from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray
fn grw_put(out:UnsafePointer[UInt8,MutAnyOrigin],word:Int,x:Int64):
    let bits=bitcast[UInt64](x)
    for b in range(8):out[word*8+b]=UInt8((bits>>UInt64(8*b))&255)
@export("graph_rust_weighted")
fn graph_rust_weighted(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2:return -1
    let count=Int(v[0]);let edges=Int(v[1]);if count<0 or count>64 or edges<0 or edges>256 or n!=c_size_t(2+3*edges):return -1
    for e in range(edges):
        let a=v[2+3*e];let b=v[3+3*e];let w=v[4+3*e]
        if a<0 or a>=count or b<0 or b>=count or w< -2147483648 or w>2147483647:return -1
    let words=1+count+4*edges;let bytes=words*8
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    var pos=0;grw_put(out,pos,Int64(count));pos+=1
    for node in range(count):
        var degree=0
        for e in range(edges):if v[2+3*e]==node or v[3+3*e]==node:degree+=1
        grw_put(out,pos,Int64(degree));pos+=1
        for e in range(edges):
            let a=v[2+3*e];let b=v[3+3*e];let w=v[4+3*e]
            if a==node:grw_put(out,pos,b);pos+=1;grw_put(out,pos,w);pos+=1
            if b==node:grw_put(out,pos,a);pos+=1;grw_put(out,pos,w);pos+=1
    return Int64(bytes)
