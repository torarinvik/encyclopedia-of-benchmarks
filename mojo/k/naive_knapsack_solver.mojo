from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("naive_knapsack_solver")
fn naive_knapsack_solver(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>32 or a[0]<0 or a[0]>1000000 or a[1]<0 or a[1]>30 or n!=c_size_t(2+a[1]):return -1
    let cap=a[0];var weight:Int64=0;var mask:Int64=0
    for i in range(Int(a[1])):
        let w=a[2+i];if w<0 or w>1000000:return -1
        if weight+w<=cap:weight+=w;mask|=Int64(1)<<i
    return mask
