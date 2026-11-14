from std.collections import List
from std.ffi import c_size_t
from std.math import isfinite
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("tsvc_s2710_nested_scalar_vector_branch_update")
fn tsvc_s2710_nested_scalar_vector_branch_update(input: UnsafePointer[Float64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[Float64, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or length < 58 or length > 323: return -1
    let n_value = input[0]
    let passes_value = input[1]
    if not isfinite(n_value) or n_value < 11.0 or n_value > 64.0: return -1
    if not isfinite(passes_value) or passes_value < 1.0 or passes_value > 8.0: return -1
    let n = Int(n_value)
    let passes = Int(passes_value)
    if Float64(n) != n_value or Float64(passes) != passes_value or length != c_size_t(3 + 5 * n): return -1
    for i in range(2, 3 + 5 * n):
        let value = input[i]
        if not isfinite(value) or value < -1.0 or value > 1.0: return -1
        if Float64(Int(value)) != value: return -1
    if output == UnsafePointer[Float64, MutAnyOrigin]() or capacity < c_size_t(3 * n): return -2
    var a = List[Float64](length=n, fill=0.0)
    var b = List[Float64](length=n, fill=0.0)
    var c = List[Float64](length=n, fill=0.0)
    for i in range(n):
        a[i] = input[3 + i]
        b[i] = input[3 + n + i]
        c[i] = input[3 + 2 * n + i]
    for _ in range(passes):
        for i in range(n):
            let d = input[3 + 3 * n + i]
            let e = input[3 + 4 * n + i]
            if a[i] > b[i]:
                a[i] += b[i] * d
                c[i] += d * d
            else:
                b[i] = a[i] + e * e
                if input[2] > 0.0:
                    c[i] = a[i] + d * d
                else:
                    c[i] += e * e
    for i in range(n):
        output[i] = a[i]
        output[n + i] = b[i]
        output[2 * n + i] = c[i]
    return Int64(3 * n)
