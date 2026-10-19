from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.math import sqrt

@export("circular_orbit_velocity")
fn circular_orbit_velocity(values: UnsafePointer[Float64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[Float64, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Float64, ImmutAnyOrigin]() or length != 2: return -1
    let mass = values[0]
    let radius = values[1]
    if mass != mass or radius != radius or mass < 1.0e-12 or mass > 1.0e25 or radius < 1.0e-12 or radius > 1.0e12: return -1
    if output == UnsafePointer[Float64, MutAnyOrigin]() or capacity < 1: return -2
    let result = sqrt(6.67430e-11 * mass / radius)
    output[0] = result
    return 1
