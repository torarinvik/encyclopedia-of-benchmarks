# Independent bounded stencil implementation; see the package license.
from std.collections import List
from std.ffi import c_size_t
from std.math import isfinite
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn jacobi_sweep(source: List[Float64], mut target: List[Float64], n: Int):
    for i in range(1, n - 1):
        for j in range(1, n - 1):
            let q = i * n + j
            target[q] = 0.2 * (source[q] + source[q - 1] + source[q + 1] + source[q + n] + source[q - n])

@export("jacobi_2d")
fn jacobi_2d(input: UnsafePointer[Float64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[Float64, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or length != 2: return -1
    let nv = input[0]; let tv = input[1]
    if not isfinite(nv) or not isfinite(tv) or nv < 1.0 or nv > 30.0 or tv < 0.0 or tv > 20.0: return -1
    let n = Int(nv); let steps = Int(tv)
    if Float64(n) != nv or Float64(steps) != tv: return -1
    let cells = n * n
    if output == UnsafePointer[Float64, MutAnyOrigin]() or capacity < c_size_t(cells): return -2
    var a = List[Float64](length=cells, fill=0.0)
    var b = List[Float64](length=cells, fill=0.0)
    for i in range(n):
        for j in range(n):
            let q = i * n + j
            a[q] = (Float64(i) * Float64(j + 2) + 2.0) / Float64(n)
            b[q] = (Float64(i) * Float64(j + 3) + 3.0) / Float64(n)
    if n > 2:
        for _ in range(steps):
            jacobi_sweep(a, b, n)
            jacobi_sweep(b, a, n)
    for i in range(cells): output[i] = a[i]
    return Int64(cells)
