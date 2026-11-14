from std.collections import List
from std.ffi import c_size_t
from std.math import isfinite
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("tsvc_s441_s443_d_sign_branch_updates")
fn tsvc_s441_s443_d_sign_branch_updates(input: UnsafePointer[Float64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[Float64, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or length < 7 or length > 259: return -1
    let mode = input[0]
    let n_value = input[1]
    let passes_value = input[2]
    if mode != 0.0 and mode != 1.0: return -1
    if not isfinite(n_value) or n_value < 1.0 or n_value > 64.0: return -1
    if not isfinite(passes_value) or passes_value < 1.0 or passes_value > 8.0: return -1
    let n = Int(n_value)
    let passes = Int(passes_value)
    if Float64(n) != n_value or Float64(passes) != passes_value or length != c_size_t(3 + 4 * n): return -1
    for i in range(3, 3 + 4 * n):
        let value = input[i]
        if not isfinite(value) or value < -1.0 or value > 1.0: return -1
        if Float64(Int(value)) != value: return -1
    if output == UnsafePointer[Float64, MutAnyOrigin]() or capacity < c_size_t(n): return -2
    var a = List[Float64](length=n, fill=0.0)
    for i in range(n): a[i] = input[3 + i]
    for _ in range(passes):
        for i in range(n):
            let b = input[3 + n + i]
            let c = input[3 + 2 * n + i]
            let d = input[3 + 3 * n + i]
            if mode == 0.0:
                if d < 0.0:
                    a[i] += b * c
                elif d == 0.0:
                    a[i] += b * b
                else:
                    a[i] += c * c
            elif d <= 0.0:
                a[i] += b * c
            else:
                a[i] += b * b
    for i in range(n): output[i] = a[i]
    return Int64(n)
