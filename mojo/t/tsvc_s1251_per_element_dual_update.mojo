from std.collections import List
from std.ffi import c_size_t
from std.math import isfinite
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("tsvc_s1251_per_element_dual_update")
fn tsvc_s1251_per_element_dual_update(input: UnsafePointer[Float64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[Float64, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or length < 6 or length > 321: return -1
    let n_value = input[0]
    if not isfinite(n_value) or n_value < 1.0 or n_value > 64.0: return -1
    let n = Int(n_value)
    if Float64(n) != n_value or length != c_size_t(1 + 5 * n): return -1
    for i in range(1, 1 + 5 * n):
        let value = input[i]
        if not isfinite(value) or value < -1.0 or value > 1.0: return -1
        if Float64(Int(value)) != value: return -1
    if output == UnsafePointer[Float64, MutAnyOrigin]() or capacity < c_size_t(2 * n): return -2
    var a = List[Float64](length=n, fill=0.0)
    var b = List[Float64](length=n, fill=0.0)
    for i in range(n):
        let saved = input[1 + n + i] + input[1 + 2 * n + i]
        b[i] = input[1 + i] + input[1 + 3 * n + i]
        a[i] = saved * input[1 + 4 * n + i]
    for i in range(n):
        output[i] = a[i]
        output[n + i] = b[i]
    return Int64(2 * n)
