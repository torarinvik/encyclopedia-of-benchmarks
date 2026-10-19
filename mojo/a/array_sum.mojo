from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("array_sum")
fn array_sum(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1: return -1
    let count = values[0]
    if count < 0 or count > 1024 or length != c_size_t(count + 1): return -1
    var total: Int64 = 0
    for i in range(Int(count)):
        let value = values[i + 1]
        if value < 0 or value > 1000000000: return -1
        total += value
    return total
