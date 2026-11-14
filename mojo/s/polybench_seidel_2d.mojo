# Bounded PolyBench Seidel profile; see package LICENSE.txt.
from std.ffi import c_size_t
from std.math import isfinite
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("polybench_seidel_2d")
fn polybench_seidel_2d(input: UnsafePointer[Float64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[Float64, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or length != 2: return -1
    let dim = input[0]
    let requested_steps = input[1]
    if not isfinite(dim) or not isfinite(requested_steps) or dim < 1.0 or dim > 6.0 or requested_steps < 0.0 or requested_steps > 4.0: return -1
    let n = Int(dim)
    let steps = Int(requested_steps)
    if Float64(n) != dim or Float64(steps) != requested_steps: return -1
    let cells = n * n
    if output == UnsafePointer[Float64, MutAnyOrigin]() or capacity < c_size_t(cells): return -2
    var matrix = InlineArray[Float64, 36](fill=0.0)
    for i in range(n):
        for j in range(n): matrix[i * n + j] = (Float64(i) * Float64(j + 2) + 2.0) / Float64(n)
    for _ in range(steps):
        for i in range(1, n - 1):
            for j in range(1, n - 1):
                let q = i * n + j
                let sum = matrix[q - n - 1] + matrix[q - n] + matrix[q - n + 1] + matrix[q - 1] + matrix[q] + matrix[q + 1] + matrix[q + n - 1] + matrix[q + n] + matrix[q + n + 1]
                matrix[q] = sum / 9.0
    for i in range(cells): output[i] = matrix[i]
    return Int64(cells)
