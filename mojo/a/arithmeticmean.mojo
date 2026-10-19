from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("arithmeticmean")
fn arithmeticmean(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 2: return -1
    let left = values[0]
    let right = values[1]
    if left < 0 or left > 9000000000000000000 or right < 0 or right > 9000000000000000000: return -1
    return ((left ^ right) >> 1) + (left & right)
