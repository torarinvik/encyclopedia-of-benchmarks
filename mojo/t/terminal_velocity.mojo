from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.math import sqrt
@export("terminal_velocity")
fn terminal_velocity(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=4:return -1.0e300
    for i in range(4):if a[i]<1 or a[i]>1000:return -1.0e300
    let numerator=2.0*Float64(a[0])*9.80665;let denominator=Float64(a[1])*Float64(a[2])*Float64(a[3])
    return sqrt(numerator/denominator)
