from std.ffi import c_size_t
from std.memory import MutAnyOrigin,UnsafePointer
@export("reverse_selection")
fn reverse_selection(v:UnsafePointer[Int64,MutAnyOrigin],n:c_size_t) abi("C"):
    if v==UnsafePointer[Int64,MutAnyOrigin]() or n<2:return
    for start in range(Int(n)-1):
        var minimum=start
        for scan in range(start+1,Int(n)):if v[scan]<v[minimum]:minimum=scan
        var left=start;var right=minimum
        while left<right:let t=v[left];v[left]=v[right];v[right]=t;left+=1;right-=1
