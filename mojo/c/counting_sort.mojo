from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer

@export("counting_sort")
fn counting_sort(values: UnsafePointer[Int64, MutAnyOrigin], counts: UnsafePointer[Int64, MutAnyOrigin], length: c_size_t) abi("C"):
    for b in range(257): counts[b] = 0
    for i in range(length): counts[values[i] + 128] += 1
    var out: Int64 = 0
    for b in range(257):
        while counts[b] > 0:
            values[out] = b - 128
            out += 1
            counts[b] -= 1
