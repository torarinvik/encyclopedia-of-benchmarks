# Bounded PolyBench LU profile; see benchmarks/l/polybench_lu/LICENSE.txt.
from std.ffi import c_size_t
from std.math import isfinite
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("polybench_lu")
fn polybench_lu(
    input: UnsafePointer[Float64, ImmutAnyOrigin],
    length: c_size_t,
    output: UnsafePointer[Float64, MutAnyOrigin],
    capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or length != 1:
        return -1
    let dimension = input[0]
    if not isfinite(dimension) or dimension < 1.0 or dimension > 6.0:
        return -1
    let n = Int(dimension)
    if Float64(n) != dimension:
        return -1
    let cells = n * n
    if output == UnsafePointer[Float64, MutAnyOrigin]() or capacity < c_size_t(cells):
        return -2

    var lower = InlineArray[Float64, 36](fill=0.0)
    var factors = InlineArray[Float64, 36](fill=0.0)
    for row in range(n):
        for column in range(row):
            lower[row * n + column] = 1.0 - Float64(column) / Float64(n)
        lower[row * n + row] = 1.0
    for k in range(n):
        for row in range(n):
            for column in range(n):
                factors[row * n + column] += lower[row * n + k] * lower[column * n + k]

    for row in range(n):
        for column in range(row):
            for k in range(column):
                factors[row * n + column] -= factors[row * n + k] * factors[k * n + column]
            factors[row * n + column] /= factors[column * n + column]
        for column in range(row, n):
            for k in range(row):
                factors[row * n + column] -= factors[row * n + k] * factors[k * n + column]
    for i in range(cells):
        output[i] = factors[i]
    return Int64(cells)
