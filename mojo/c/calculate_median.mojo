from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("calculate_median")
fn calculate_median(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length == 0 or length > 1024:
        return -9223372036854775808
    let middle = Int64(length // 2)
    if length % 2 == 1:
        return values[middle] * 2
    return values[middle - 1] + values[middle]
