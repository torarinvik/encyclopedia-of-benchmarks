from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("archimedes_principle_of_buoyant_force")
fn archimedes_principle_of_buoyant_force(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Float64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 2 or values[0] < 1 or values[0] > 1000 or values[1] < 1 or values[1] > 1000:
        return -1.0e300
    return (Float64(values[0]) * 9.80665) * Float64(values[1])
