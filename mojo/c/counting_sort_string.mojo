from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("counting_sort_string")
fn counting_sort_string(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 4096: return -1
    let n = values[0]
    if n < 0 or n > 4095 or length != n + 1: return -1
    var counts = InlineArray[Int64, 94](0)
    for i in range(n):
        let c = values[i + 1]
        if c < 33 or c > 126: return -1
        counts[c - 33] += 1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < n: return -2
    var out: Int64 = 0
    for b in range(94):
        for j in range(counts[b]):
            output[out] = UInt8(b + 33)
            out += 1
    return n
