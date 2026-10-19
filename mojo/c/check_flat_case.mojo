from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("check_flat_case")
fn check_flat_case(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if length > 4096 or (length != 0 and values == UnsafePointer[Int64, ImmutAnyOrigin]()): return -2
    for i in range(length):
        if values[i] < 32 or values[i] > 126: return -2
    for i in range(length):
        if values[i] < 97 or values[i] > 122: return 0
    return 1
