from std.collections import List
from std.ffi import c_size_t
from std.math import isfinite
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("tsvc_s2275_matrix_vector_axpy_interleave")
fn tsvc_s2275_matrix_vector_axpy_interleave(input: UnsafePointer[Float64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[Float64, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or length < 9 or length > 226: return -1
    let n_value = input[0]
    let passes_value = input[1]
    if not isfinite(n_value) or n_value < 1.0 or n_value > 8.0: return -1
    if not isfinite(passes_value) or passes_value < 1.0 or passes_value > 8.0: return -1
    let n = Int(n_value)
    let passes = Int(passes_value)
    let cells = n * n
    if Float64(n) != n_value or Float64(passes) != passes_value or length != c_size_t(2 + 3 * cells + 4 * n): return -1
    for i in range(2, 2 + 3 * cells + 4 * n):
        let value = input[i]
        if not isfinite(value) or value < -1.0 or value > 1.0: return -1
        if Float64(Int(value)) != value: return -1
    if output == UnsafePointer[Float64, MutAnyOrigin]() or capacity < c_size_t(cells + n): return -2
    var aa = List[Float64](length=cells, fill=0.0)
    var a = List[Float64](length=n, fill=0.0)
    let vector = 2 + 3 * cells
    for i in range(cells): aa[i] = input[2 + i]
    for i in range(n): a[i] = input[vector + i]
    for _ in range(passes):
        for col in range(n):
            for row in range(n):
                let cell = row * n + col
                aa[cell] += input[2 + cells + cell] * input[2 + 2 * cells + cell]
            a[col] = input[vector + n + col] + input[vector + 2 * n + col] * input[vector + 3 * n + col]
    for i in range(cells): output[i] = aa[i]
    for i in range(n): output[cells + i] = a[i]
    return Int64(cells + n)
