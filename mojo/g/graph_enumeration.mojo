from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray
fn ge_hash(h0:UInt64,x0:Int64)->UInt64:
    var h=h0;var x=bitcast[UInt64](x0)
    for b in range(8):h=(h^(x&255))*UInt64(1099511628211);x>>=8
    return h
@export("graph_enumeration")
fn graph_enumeration(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or v[0]<0 or v[0]>16:return -1
    let count=Int(v[0]);if n<c_size_t(1+count):return -1
    var labels=InlineArray[Int64,16](fill=0);var sorted=InlineArray[Int64,16](fill=0);var ranks=InlineArray[Int,16](fill=0);var off=1+count
    for i in range(count):
        labels[i]=v[1+i];if labels[i]< -1000000 or labels[i]>1000000:return -1
        for j in range(i):if labels[i]==labels[j]:return -1
        sorted[i]=labels[i]
    for i in range(count):
        for j in range(i+1,count):if sorted[j]<sorted[i]:let t=sorted[i];sorted[i]=sorted[j];sorted[j]=t
    for i in range(count):
        while ranks[i]<count and sorted[ranks[i]]!=labels[i]:ranks[i]+=1
    var degrees=InlineArray[Int,16](fill=0);var adj=InlineArray[Int64,512](fill=0)
    for i in range(count):
        if off>=Int(n):return -1
        let d=Int(v[off]);off+=1;if d<0 or d>32 or off+d>Int(n):return -1;degrees[i]=d
        for j in range(d):
            let x=v[off];off+=1;var found=False
            for k in range(count):if labels[k]==x:found=True
            if not found:return -1
            adj[i*32+j]=x
    if off!=Int(n):return -1
    var h=UInt64(14695981039346656037);h=ge_hash(h,Int64(count+1));h=ge_hash(h,0)
    for s in range(count):
        var original=0
        while labels[original]!=sorted[s]:original+=1
        h=ge_hash(h,Int64(degrees[original]))
        for j in range(degrees[original]):
            let x=adj[original*32+j];var k=0
            while labels[k]!=x:k+=1
            h=ge_hash(h,Int64(ranks[k]+1))
    return bitcast[Int64](h)
