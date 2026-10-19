from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("set_kth_bit")
fn set_kth_bit(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=2 or a[0]<0 or a[0]>2147483647 or a[1]<0 or a[1]>30:return -1
    return a[0]|(1<<Int(a[1]))
