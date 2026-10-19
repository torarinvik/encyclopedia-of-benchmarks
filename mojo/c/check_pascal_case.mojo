from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("check_pascal_case")
fn check_pascal_case(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if length > 4096 or (length != 0 and values == UnsafePointer[Int64, ImmutAnyOrigin]()): return -2
    for i in range(length):
        if values[i] < 32 or values[i] > 126: return -2
    if length == 0 or values[0] < 65 or values[0] > 90: return 0
    for i in range(length):
        let value = values[i]
        if not ((value >= 97 and value <= 122) or (value >= 65 and value <= 90)): return 0
    return 1
