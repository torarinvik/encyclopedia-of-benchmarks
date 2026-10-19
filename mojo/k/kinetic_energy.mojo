from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("kinetic_energy")
fn kinetic_energy(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=2:return -1.0e300
    if a[0]<0 or a[0]>1000 or a[1]< -1000 or a[1]>1000:return -1.0e300
    let speed=abs(a[1]);return ((0.5*Float64(a[0]))*Float64(speed))*Float64(speed)
