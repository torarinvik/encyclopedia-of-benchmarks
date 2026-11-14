from std.collections import List
from std.ffi import c_size_t
from std.math import isfinite
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("tsvc_s351_direct_unrolled_saxpy")
fn tsvc_s351_direct_unrolled_saxpy(input: UnsafePointer[Float64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[Float64, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or length < 12 or length > 82: return -1
    let n_value = input[0]
    if not isfinite(n_value) or n_value < 5.0 or n_value > 40.0: return -1
    let n = Int(n_value)
    if Float64(n) != n_value or n % 5 != 0 or length != c_size_t(2 + 2 * n): return -1
    for i in range(1, 2 + 2 * n):
        let value = input[i]
        if not isfinite(value) or value < -1.0 or value > 1.0: return -1
        if Float64(Int(value)) != value: return -1
    if output == UnsafePointer[Float64, MutAnyOrigin]() or capacity < c_size_t(n): return -2
    var a = List[Float64](length=n, fill=0.0)
    for i in range(n): a[i] = input[2 + i]
    let alpha = input[1]
    for group in range(n // 5):
        let base = 5 * group
        for offset in range(5):
            let index = base + offset
            a[index] = a[index] + alpha * input[2 + n + index]
    for i in range(n): output[i] = a[i]
    return Int64(n)
