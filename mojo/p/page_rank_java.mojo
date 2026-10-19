from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("page_rank_java")
fn page_rank_java(v:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Float64,ImmutAnyOrigin]() or n<3 or n>19:return -1
    for i in range(Int(n)):if not is_finite(v[i]):return -1
    let nodes=Int(v[0]);let iters=Int(v[1]);if v[0]!=Float64(nodes) or v[1]!=Float64(iters) or nodes<1 or nodes>4 or iters<1 or iters>8 or Int(n)!=2+nodes*nodes:return -1
    var a=InlineArray[Int64,16](fill=0);var deg=InlineArray[Int64,4](fill=0)
    for i in range(nodes*nodes):if v[2+i]!=0.0 and v[2+i]!=1.0:return -1;a[i]=Int64(v[2+i])
    for i in range(nodes):if a[i*nodes+i]!=0:return -1;for j in range(nodes):deg[i]+=a[i*nodes+j]
    var r=InlineArray[Float64,4](fill=0.0);var next=InlineArray[Float64,4](fill=0.0)
    for i in range(nodes):r[i]=1.0/Float64(nodes)
    for _ in range(iters):
        for t in range(nodes):
            var incoming=0.0
            for s in range(nodes):
                if a[s*nodes+t]==1 and deg[s]>0:incoming+=r[s]/Float64(deg[s])
            next[t]=0.5+0.5*incoming
        for i in range(nodes):r[i]=next[i]
    if o==UnsafePointer[Float64,MutAnyOrigin]() or cap<c_size_t(nodes):return -2
    for i in range(nodes):o[i]=r[i]
    return Int64(nodes)
