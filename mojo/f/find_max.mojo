from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("find_max")
fn find_max(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if length == 0 or length > 512 or values == UnsafePointer[Int64, ImmutAnyOrigin](): return -1
    var result = values[0]
    for i in range(1, length):
        if values[i] > result: result = values[i]
    return result
