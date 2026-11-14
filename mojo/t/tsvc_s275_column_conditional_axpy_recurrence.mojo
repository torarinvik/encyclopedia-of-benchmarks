from std.collections import List
from std.ffi import c_size_t
from std.math import isfinite
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("tsvc_s275_column_conditional_axpy_recurrence")
fn tsvc_s275_column_conditional_axpy_recurrence(input: UnsafePointer[Float64, ImmutAnyOrigin],
        length: c_size_t, output: UnsafePointer[Float64, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or length < 2 or length > 193: return -1
    let dimension = input[0]
    if not isfinite(dimension) or dimension < 1.0 or dimension > 8.0: return -1
    let n = Int(dimension)
    if Float64(n) != dimension: return -1
    let cells = n * n
    if length != c_size_t(1 + 3 * cells): return -1
    for i in range(1, 1 + 3 * cells):
        let value = input[i]
        if not isfinite(value) or value < -16.0 or value > 16.0: return -1
        if Float64(Int(value)) != value: return -1
    if output == UnsafePointer[Float64, MutAnyOrigin]() or capacity < c_size_t(cells): return -2
    var a = List[Float64](length=cells, fill=0.0)
    for i in range(cells): a[i] = input[1 + i]
    for col in range(n):
        if a[col] > 0.0:
            for row in range(1, n):
                let index = row * n + col
                a[index] = a[index - n] + input[1 + cells + index] * input[1 + 2 * cells + index]
    for i in range(cells): output[i] = a[i]
    return Int64(cells)
