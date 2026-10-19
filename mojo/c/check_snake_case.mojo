from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("check_snake_case")
fn check_snake_case(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if length > 4096 or (length != 0 and values == UnsafePointer[Int64, ImmutAnyOrigin]()): return -2
    var found: Int64 = 0
    for i in range(length):
        if values[i] < 32 or values[i] > 126: return -2
        if values[i] == 95: found = 1
    return found
