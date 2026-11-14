from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("tsvc_s1221_lag4_add_recurrence")
fn tsvc_s1221_lag4_add_recurrence(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 11 or length > 65: return -1
    let n0 = input[0]
    if n0 < 5 or n0 > 32 or length != c_size_t(1 + 2 * n0): return -1
    let n = Int(n0)
    var b = List[Int64](length=n, fill=0)
    for i in range(n):
        let a = input[1 + i]; let value = input[1 + n + i]
        if a < -10 or a > 10 or value < -10 or value > 10: return -1
        b[i] = value
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(8 * n): return -2
    for i in range(4, n): b[i] = b[i - 4] + input[1 + i]
    for i in range(n):
        for byte in range(8): output[8 * i + byte] = UInt8((b[i] >> (8 * byte)) & 255)
    return n0
