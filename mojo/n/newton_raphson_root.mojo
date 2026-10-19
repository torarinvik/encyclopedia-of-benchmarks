from std.memory import ImmutAnyOrigin, UnsafePointer
@export("newton_raphson_root")
fn newton_raphson_root(x:Float64) abi("C")->Float64:
    if x<1.0 or x>4.0:return -1.0e300
    var y=Float32(x)
    for _ in range(1000):
        let f=y*y-Float32(3.0)
        if abs(f)<=Float32(1.0e-6):return Float64(y)
        y=y-f/(Float32(2.0)*y)
    return Float64(y)
