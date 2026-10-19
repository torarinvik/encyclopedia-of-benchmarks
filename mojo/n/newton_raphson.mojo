from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("newton_raphson")
fn newton_raphson(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=2:return -1.0e300
    let rad=a[0];let quarters=a[1]
    if rad<2 or rad>4 or quarters<4 or quarters>8:return -1.0e300
    var x=Float64(quarters)/4.0
    for _ in range(8):x=x-(x*x-Float64(rad))/(2.0*x)
    return x
