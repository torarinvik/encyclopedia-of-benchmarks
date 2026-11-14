from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("tsvc_s132_shifted_row_update")
fn tsvc_s132_shifted_row_update(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 8 or length > 194: return -1
    let n0 = input[0]
    if n0 < 2 or n0 > 64 or length != c_size_t(2 + 3 * n0): return -1
    let n = Int(n0)
    for i in range(1, 2 + 3 * n):
        if input[i] < -1000000 or input[i] > 1000000: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(8 * n): return -2
    var target = List[Int64](length=n, fill=0)
    for i in range(n):
        target[i] = input[1 + n + i]
    let c1 = input[1 + 3 * n]
    for i in range(1, n):
        target[i] = input[i] + input[1 + 2 * n + i] * c1
    for i in range(n):
        for byte in range(8): output[8 * i + byte] = UInt8((target[i] >> (8 * byte)) & 255)
    return Int64(n)
