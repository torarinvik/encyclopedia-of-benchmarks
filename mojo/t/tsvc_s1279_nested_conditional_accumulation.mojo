from std.collections import List
from std.ffi import c_size_t
from std.math import isfinite
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("tsvc_s1279_nested_conditional_accumulation")
fn tsvc_s1279_nested_conditional_accumulation(input: UnsafePointer[Float64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[Float64, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or length < 7 or length > 322: return -1
    let n_value = input[0]
    let passes_value = input[1]
    if not isfinite(n_value) or n_value < 1.0 or n_value > 64.0: return -1
    if not isfinite(passes_value) or passes_value < 1.0 or passes_value > 8.0: return -1
    let n = Int(n_value)
    let passes = Int(passes_value)
    if Float64(n) != n_value or Float64(passes) != passes_value or length != c_size_t(2 + 5 * n): return -1
    for i in range(2, 2 + 5 * n):
        let value = input[i]
        if not isfinite(value) or value < -1.0 or value > 1.0: return -1
        if Float64(Int(value)) != value: return -1
    if output == UnsafePointer[Float64, MutAnyOrigin]() or capacity < c_size_t(n): return -2
    var c = List[Float64](length=n, fill=0.0)
    for i in range(n):
        c[i] = input[2 + 2 * n + i]
    for _ in range(passes):
        for i in range(n):
            let a = input[2 + i]
            if a < 0.0 and input[2 + n + i] > a:
                c[i] += input[2 + 3 * n + i] * input[2 + 4 * n + i]
    for i in range(n):
        output[i] = c[i]
    return Int64(n)
