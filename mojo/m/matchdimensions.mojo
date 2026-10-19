from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("matchdimensions")
fn matchdimensions(v: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t) abi("C") -> Int64:
    if v == UnsafePointer[Int64, ImmutAnyOrigin]() or n != 4: return -1
    for i in range(4):
        if v[i] < 0 or v[i] > 65535: return -1
    return 1 if v[0] == v[2] and v[1] == v[3] else 0
