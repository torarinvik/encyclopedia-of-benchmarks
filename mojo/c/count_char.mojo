from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("count_char")
fn count_char(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if length > 4096 or (length != 0 and values == UnsafePointer[Int64, ImmutAnyOrigin]()): return -1
    var count: Int64 = 0
    for i in range(length):
        let code = values[i]
        if code < 0 or code > 127: return -1
        if code != 9 and code != 10 and code != 11 and code != 12 and code != 13 and code != 32: count += 1
    return count
