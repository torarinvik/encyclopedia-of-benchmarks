from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("is_monotonic")
fn monotonic_array(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if n>256 or (n!=0 and v==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    for i in range(1,Int(n)):
        if v[i-1]>v[i]:
            for j in range(1,Int(n)):if v[j-1]<v[j]:return 0
            return 1
    return 1
