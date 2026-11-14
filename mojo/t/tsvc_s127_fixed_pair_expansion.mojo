from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("tsvc_s127_fixed_pair_expansion")
fn tsvc_s127_fixed_pair_expansion(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 5 or length > 129: return -1
    let n0 = input[0]
    if n0 < 1 or n0 > 32 or length != c_size_t(1 + 4 * n0): return -1
    let n = Int(n0)
    for i in range(1, 1 + 4 * n):
        if input[i] < -100 or input[i] > 100: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(16 * n): return -2
    var values = List[Int64](length=2 * n, fill=0)
    for i in range(n):
        let b = input[1 + i]; let c = input[1 + n + i]
        let d = input[1 + 2 * n + i]; let e = input[1 + 3 * n + i]
        values[2 * i] = b + c * d
        values[2 * i + 1] = b + d * e
    for i in range(2 * n):
        for byte in range(8): output[8 * i + byte] = UInt8((values[i] >> (8 * byte)) & 255)
    return Int64(2 * n)
