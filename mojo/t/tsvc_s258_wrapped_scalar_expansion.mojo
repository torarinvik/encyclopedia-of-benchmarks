from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("tsvc_s258_wrapped_scalar_expansion")
fn tsvc_s258_wrapped_scalar_expansion(input: UnsafePointer[Int64, ImmutAnyOrigin],
        length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 5 or length > 257: return -1
    let n0 = input[0]
    if n0 < 1 or n0 > 64 or length != c_size_t(1 + 4 * n0): return -1
    let n = Int(n0)
    for i in range(1, 1 + 4 * n):
        if input[i] < 0 or input[i] > 2: return -1
    var b = List[Int64](length=n, fill=0)
    var e = List[Int64](length=n, fill=0)
    var scalar = Int64(0)
    for i in range(n):
        let a = input[1 + i]; let c = input[1 + n + i]
        let d = input[1 + 2 * n + i]; let aa = input[1 + 3 * n + i]
        if a > 0: scalar = d * d
        b[i] = scalar * c + d
        e[i] = (scalar + 1) * aa
    var sum_b = Int64(0); var sum_e = Int64(0)
    for i in range(n): sum_b += b[i]; sum_e += e[i]
    return sum_b + sum_e
