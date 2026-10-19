from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("check_if_array_is_sorted_and_rotated")
fn check_if_array_is_sorted_and_rotated(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if length > 256 or (length != 0 and values == UnsafePointer[Int64, ImmutAnyOrigin]()): return -1
    for i in range(length):
        if values[i] < -2147483648 or values[i] > 2147483647: return -1
    if length == 0: return 1
    var descents: Int64 = 0
    for i in range(length):
        let next = (i + 1) % length
        if values[i] > values[next]:
            descents += 1
            if descents > 1: return 0
    return 1
