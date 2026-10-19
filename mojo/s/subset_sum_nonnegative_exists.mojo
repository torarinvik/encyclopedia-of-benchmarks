from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("subset_sum_nonnegative_exists")
fn subset_sum_nonnegative_exists(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n==0 or n>65:return -1
    let target=v[0]
    if target<0 or target>4096:return -1
    for i in range(1,Int(n)):if v[i]<0 or v[i]>4096:return -1
    var reach=InlineArray[Bool,4097](fill=False);reach[0]=True
    for i in range(1,Int(n)):
        let item=Int(v[i]);var s=Int(target)
        while s>=item:
            if reach[s-item]:reach[s]=True
            s-=1
    return 1 if reach[Int(target)] else 0
