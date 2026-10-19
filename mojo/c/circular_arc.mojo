from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("circular_arc")
fn circular_arc(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Float64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 3: return -1.0e300
    let mode = input[0]
    let radius = input[1]
    let degrees = input[2]
    if (mode != 0 and mode != 1) or radius < -1000000 or radius > 1000000 or degrees < -360000 or degrees > 360000: return -1.0e300
    let angle = Float64(degrees) * (3.14159265358979323846 / 180.0)
    if mode == 0: return Float64(radius) * angle
    return Float64(radius * radius) * angle / 2.0
