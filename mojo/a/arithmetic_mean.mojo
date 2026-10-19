from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("arithmetic_mean")
fn arithmetic_mean(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Float64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length == 0 or length > 64: return -1.0e300
    var total: Int64 = 0
    for i in range(Int(length)):
        if values[i] < -1000000 or values[i] > 1000000: return -1.0e300
        total += values[i]
    return Float64(total) / Float64(length)
