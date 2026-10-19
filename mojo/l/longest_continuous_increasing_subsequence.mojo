from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("longest_continuous_increasing_subsequence")
fn longest_continuous_increasing_subsequence(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if n>10000 or (n>0 and v==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    for i in range(Int(n)):
        if v[i] < -1000000 or v[i]>1000000:return -1
    if n==0:return 0
    var cur=1;var best=1
    for i in range(1,Int(n)):
        if v[i]>v[i-1]:cur+=1
        else:cur=1
        best=max(best,cur)
    return Int64(best)
