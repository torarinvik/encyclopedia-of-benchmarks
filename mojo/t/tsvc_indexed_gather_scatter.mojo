from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("tsvc_indexed_gather_scatter")
fn tsvc_indexed_gather_scatter(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 6 or length > 82: return -1
    let mode = input[0]
    let n0 = input[1]
    if (mode != 491 and mode != 4113) or n0 < 1 or n0 > 16: return -1
    let n = Int(n0)
    var count = 4
    if mode == 491: count = 5
    if length != c_size_t(2 + count * n): return -1
    for i in range(n):
        if input[2 + i] < 0 or input[2 + i] >= n0: return -1
    for i in range(2 + 2 * n, 2 + count * n):
        if input[i] < -1000000 or input[i] > 1000000: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(8 * n): return -2
    var state = List[Int64](length=n, fill=0)
    for i in range(n): state[i] = input[2 + n + i]
    for i in range(n):
        let index = Int(input[2 + i])
        if mode == 491:
            state[index] = input[2 + 2 * n + i] + input[2 + 3 * n + i] * input[2 + 4 * n + i]
        else:
            state[index] = input[2 + 2 * n + index] + input[2 + 3 * n + i]
    for i in range(n):
        for byte in range(8): output[8 * i + byte] = UInt8((state[i] >> (8 * byte)) & 255)
    return Int64(n)
