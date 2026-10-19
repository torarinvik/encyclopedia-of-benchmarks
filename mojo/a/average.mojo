from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("average")
fn average(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Float64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length == 0 or length > 4096: return -1.0e300
    var sum: Int64 = 0
    for i in range(Int(length)):
        if values[i] < -1000000000 or values[i] > 1000000000: return -1.0e300
        sum += values[i]
    return Float64(sum) / Float64(length)
