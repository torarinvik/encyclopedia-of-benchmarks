# Independent bounded implementation of the Q15 operation; see package NOTICE.txt.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("edn_vec_mpy1")
fn edn_vec_mpy1(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 130: return -1
    let n0 = input[0]
    if n0 < 1 or n0 > 64 or length != c_size_t(2 + 2 * n0): return -1
    let n = Int(n0)
    for i in range(1, 2 + 2 * n):
        if input[i] < -1024 or input[i] > 1023: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(8 * n): return -2
    var values = List[Int64](length=n, fill=0)
    let scale = input[1 + 2 * n]
    for i in range(n):
        values[i] = input[1 + i] + ((scale * input[1 + n + i]) >> 15)
    for i in range(n):
        for byte in range(8): output[8 * i + byte] = UInt8((values[i] >> (8 * byte)) & 255)
    return Int64(8 * n)
