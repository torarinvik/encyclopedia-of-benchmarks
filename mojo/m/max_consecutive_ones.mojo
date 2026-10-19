from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer

@export("max_consecutive_ones")
fn max_consecutive_ones(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if n>4096:return -1
    var best=0;var run=0
    for i in range(Int(n)):
        if v[i]!=0 and v[i]!=1:return -1
        if v[i]==1:run+=1;if run>best:best=run
        else:run=0
    return Int64(best)
