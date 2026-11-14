from std.collections import List
from std.ffi import c_size_t
from std.math import isfinite
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("tsvc_s111_odd_index_neighbor_update")
fn tsvc_s111_odd_index_neighbor_update(input: UnsafePointer[Float64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[Float64, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or length < 3 or length > 129: return -1
    let n_value = input[0]
    if not isfinite(n_value) or n_value < 1.0 or n_value > 64.0: return -1
    let n = Int(n_value)
    if Float64(n) != n_value or length != c_size_t(1 + 2 * n): return -1
    for i in range(1, 1 + 2 * n):
        let value = input[i]
        if not isfinite(value) or value < -1000.0 or value > 1000.0: return -1
        if Float64(Int(value)) != value: return -1
    if output == UnsafePointer[Float64, MutAnyOrigin]() or capacity < c_size_t(n): return -2
    var a = List[Float64](length=n, fill=0.0)
    for i in range(n): a[i] = input[1 + i]
    for step in range(n // 2):
        let i = 2 * step + 1
        a[i] = a[i - 1] + input[1 + n + i]
    for i in range(n): output[i] = a[i]
    return Int64(n)
