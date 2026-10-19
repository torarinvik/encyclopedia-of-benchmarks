from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("kelly_criterion")
fn kelly_criterion(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=2:return -1.0e300
    if a[0]<1 or a[0]>999999 or a[1]<1000 or a[1]>100000000:return -1.0e300
    let p=Float64(a[0])/1000000.0;let b=Float64(a[1])/1000000.0;let q=1.0-p
    return (p*b-q)/b
