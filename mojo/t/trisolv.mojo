# Bounded PolyBench triangular solve; see package LICENSE.txt.
from std.ffi import c_size_t
from std.math import isfinite
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("trisolv")
fn trisolv(input: UnsafePointer[Float64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[Float64, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or length != 1: return -1
    let dimension = input[0]
    if not isfinite(dimension) or dimension < 1.0 or dimension > 40.0: return -1
    let n = Int(dimension)
    if Float64(n) != dimension: return -1
    if output == UnsafePointer[Float64, MutAnyOrigin]() or capacity < c_size_t(n): return -2
    var lower = InlineArray[Float64, 1600](fill=0.0)
    var rhs = InlineArray[Float64, 40](fill=0.0)
    var result = InlineArray[Float64, 40](fill=0.0)
    for i in range(n):
        rhs[i] = Float64(i)
        for j in range(i + 1): lower[i * n + j] = Float64(i + n - j + 1) * 2.0 / Float64(n)
    for i in range(n):
        result[i] = rhs[i]
        for j in range(i): result[i] -= lower[i * n + j] * result[j]
        result[i] /= lower[i * n + i]
    for i in range(n): output[i] = result[i]
    return Int64(n)
