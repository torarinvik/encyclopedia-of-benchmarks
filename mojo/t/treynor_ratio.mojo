from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("treynor_ratio")
fn treynor_ratio(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=3:return -1.0e300
    for i in range(3):
        if a[i]< -1000 or a[i]>1000:return -1.0e300
    if a[2]==0:return -1.0e300
    return Float64(a[0]-a[1])/Float64(a[2])
