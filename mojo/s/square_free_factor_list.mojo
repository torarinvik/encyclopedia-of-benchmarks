from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("square_free_factor_list")
fn square_free_factor_list(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if n>256 or (n>0 and v==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    for i in range(Int(n)):
        if v[i]< -2147483648 or v[i]>2147483647:return -1
        for j in range(i):if v[i]==v[j]:return 0
    return 1
