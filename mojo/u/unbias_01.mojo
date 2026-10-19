from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("unbias_01")
fn unbias_01(v: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t) abi("C") -> Int64:
    if n > 257 or v == UnsafePointer[Int64, ImmutAnyOrigin]() or n < 1: return -1
    let count = Int(v[0])
    if count < 0 or count > 256 or n != c_size_t(count + 1): return -1
    for i in range(count):
        if v[i + 1] != 0 and v[i + 1] != 1: return -1
    var i = 0
    while i + 1 < count:
        if v[i + 1] != v[i + 2]: return v[i + 1]
        i += 2
    return -1
