from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("centripetal_force")
fn centripetal_force(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Float64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 3: return -1.0e300
    let mass = values[0]
    let velocity = values[1]
    let radius = values[2]
    if mass < 0 or mass > 1000 or velocity < -1000 or velocity > 1000 or radius < 1 or radius > 1000: return -1.0e300
    let velocity_squared = Float64(velocity) * Float64(velocity)
    return (Float64(mass) * velocity_squared) / Float64(radius)
