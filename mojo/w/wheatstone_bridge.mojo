from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("wheatstone_bridge")
fn wheatstone_bridge(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=3:return -1.0e300
    if a[0]<1 or a[0]>1000000 or a[1]<1 or a[1]>1000000 or a[2]<1 or a[2]>1000000:return -1.0e300
    return (Float64(a[1])/Float64(a[0]))*Float64(a[2])
