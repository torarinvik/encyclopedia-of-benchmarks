from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("hookes_law")
fn hookes_law(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=2 or a[0]<1 or a[0]>1000 or a[1]< -1000 or a[1]>1000:return -1.0e300
    return -Float64(a[0])*Float64(a[1])
