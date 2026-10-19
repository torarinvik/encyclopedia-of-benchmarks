from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("newton_raphson_method")
fn newton_raphson_method(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=2:return -1.0e300
    let x0=a[0];let limit=a[1]
    if x0<2000 or x0>4000 or limit<1 or limit>32:return -1.0e300
    var c=Float64(x0)/1000.0
    for _ in range(Int(limit)):
        let m=c*c*c-4.0*c-9.0
        let d=3.0*c*c-4.0
        let z=c-m/d;c=z
        if abs(m)<1.0e-10:break
    return c
