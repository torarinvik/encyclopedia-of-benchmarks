from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("tsvc_s353_unrolled_sparse_saxpy")
fn tsvc_s353_unrolled_sparse_saxpy(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 17 or length > 62: return -1
    let n0 = input[0]; let alpha = input[1]
    if n0 < 5 or n0 > 20 or n0 % 5 != 0 or alpha < -8 or alpha > 8 or length != c_size_t(2 + 3 * n0): return -1
    let n = Int(n0)
    var a = List[Int64](length=n, fill=0)
    for i in range(n):
        let av = input[2 + i]; let bv = input[2 + n + i]; let index = input[2 + 2 * n + i]
        if av < -1_000_000 or av > 1_000_000 or bv < -1_000_000 or bv > 1_000_000 or index < 0 or index >= n0: return -1
        a[i] = av
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(8 * n): return -2
    for group in range(n // 5):
        for offset in range(5):
            let i = 5 * group + offset
            a[i] += alpha * input[2 + n + Int(input[2 + 2 * n + i])]
    for i in range(n):
        for byte in range(8): output[8 * i + byte] = UInt8((a[i] >> (8 * byte)) & 255)
    return n0
