from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("tsvc_vag_indexed_gather_copy")
fn tsvc_vag_indexed_gather_copy(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 129: return -1
    let n0 = input[0]
    if n0 < 1 or n0 > 64 or length != c_size_t(1 + 2 * n0): return -1
    let n = Int(n0)
    for i in range(n):
        if input[1 + i] < 0 or input[1 + i] >= n0: return -1
        if input[1 + n + i] < -1000000 or input[1 + n + i] > 1000000: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(8 * n): return -2
    var result = List[Int64](length=n, fill=0)
    for i in range(n): result[i] = input[1 + n + Int(input[1 + i])]
    for i in range(n):
        for byte in range(8): output[8 * i + byte] = UInt8((result[i] >> (8 * byte)) & 255)
    return Int64(n)
