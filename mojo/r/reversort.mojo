from std.ffi import c_size_t
from std.memory import MutAnyOrigin,UnsafePointer
@export("reversort")
fn reversort(v:UnsafePointer[Int64,MutAnyOrigin],n:c_size_t) abi("C"):
    if v==UnsafePointer[Int64,MutAnyOrigin]() or n<2:return
    for i in range(Int(n)-1):
        var m=i
        for j in range(i+1,Int(n)):if v[j]<v[m]:m=j
        var l=i;var r=m
        while l<r:let t=v[l];v[l]=v[r];v[r]=t;l+=1;r-=1
