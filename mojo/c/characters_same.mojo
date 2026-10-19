from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("characters_same")
fn characters_same(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if length > 256 or (length != 0 and values == UnsafePointer[Int64, ImmutAnyOrigin]()): return -1
    for i in range(length):
        if values[i] < 0 or values[i] > 127: return -1
    if length == 0: return 1
    let first = values[0]
    for i in range(1, length):
        if values[i] != first: return 0
    return 1
