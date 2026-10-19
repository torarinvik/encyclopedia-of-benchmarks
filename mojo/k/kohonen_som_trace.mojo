from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.math import isfinite
@export("kohonen_som_trace")
fn kohonen_som_trace(a:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Float64,ImmutAnyOrigin]() or n<4 or n>41:return -1
    for i in range(4):if not isfinite(a[i]) or Float64(Int64(a[i]))!=a[i]:return -1
    let nodes=Int(a[0]);let f=Int(a[1]);let rad=Int(a[2]);let code=Int(a[3])
    if nodes<1 or nodes>8 or f<1 or f>4 or rad<0 or rad>8 or code<1 or code>16 or n!=c_size_t(4+f+nodes*f):return -1
    var sample=InlineArray[Float64,4]();var w=InlineArray[Float64,32]()
    for i in range(f):let x=a[4+i];if not isfinite(x) or Float64(Int64(x))!=x or x< -8.0 or x>8.0:return -1;sample[i]=x
    for i in range(nodes*f):let x=a[4+f+i];if not isfinite(x) or Float64(Int64(x))!=x or x< -8.0 or x>8.0:return -1;w[i]=x
    var bmu=0;var best:Float64=0.0
    for j in range(f):let d=sample[j]-w[j];best+=d*d
    for node in range(1,nodes):
        var dist:Float64=0.0
        for j in range(f):let d=sample[j]-w[node*f+j];dist+=d*d
        if dist<best:best=dist;bmu=node
    let alpha=Float64(code)/16.0;let lo=max(0,bmu-rad);let hi=min(nodes,bmu+rad+1)
    for node in range(lo,hi):
        for j in range(f):w[node*f+j]+=alpha*(sample[j]-w[node*f+j])
    if o==UnsafePointer[Float64,MutAnyOrigin]() or cap<c_size_t(nodes*f):return -2
    for i in range(nodes*f):o[i]=w[i]
    return nodes*f
