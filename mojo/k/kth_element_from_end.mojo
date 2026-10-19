from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("kth_element_from_end")
fn kth_element_from_end(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>65:return -1
    let k=a[0];let count=Int(n)-1
    if k<1 or k>count:return -1
    for i in range(1,Int(n)):if a[i]<0 or a[i]>100000:return -1
    return a[Int(n)-Int(k)]
