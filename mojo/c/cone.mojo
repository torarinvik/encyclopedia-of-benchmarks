from std.ffi import c_size_t
from std.math import sqrt
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("cone")
fn cone(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Float64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 3: return -1.0e300
    let operation = values[0]
    let radius = values[1]
    let height = values[2]
    if (operation != 0 and operation != 1) or radius < 0 or radius > 1000 or height < 0 or height > 1000: return -1.0e300
    let r = Float64(radius)
    let h = Float64(height)
    let radius_squared = r * r
    let base_area = radius_squared * 3.14159265358979323846
    if operation == 0: return (base_area * h * 1.0) / 3.0
    return base_area + 3.14159265358979323846 * r * sqrt(radius_squared + h * h)
