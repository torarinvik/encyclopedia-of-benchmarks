# Independent bounded implementation; see the package for PolyBench provenance.
from std.collections import List
from std.ffi import c_size_t
from std.math import isfinite
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn sweep(source: List[Float64], mut target: List[Float64], n: Int):
    for i in range(1, n - 1):
        for j in range(1, n - 1):
            for k in range(1, n - 1):
                let q = i * n * n + j * n + k
                let center = source[q]
                target[q] = 0.125 * (source[q + n * n] - 2.0 * center + source[q - n * n]) + 0.125 * (source[q + n] - 2.0 * center + source[q - n]) + 0.125 * (source[q + 1] - 2.0 * center + source[q - 1]) + center

@export("polybench_heat_3d")
fn polybench_heat_3d(input: UnsafePointer[Float64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[Float64, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or length != 2: return -1
    let nv = input[0]; let sv = input[1]
    if not isfinite(nv) or not isfinite(sv) or nv < 1.0 or nv > 6.0 or sv < 0.0 or sv > 4.0: return -1
    let n = Int(nv); let steps = Int(sv)
    if Float64(n) != nv or Float64(steps) != sv: return -1
    let cells = n * n * n
    if output == UnsafePointer[Float64, MutAnyOrigin]() or capacity < c_size_t(cells): return -2
    var a = List[Float64](length=cells, fill=0.0)
    var b = List[Float64](length=cells, fill=0.0)
    for i in range(n):
        for j in range(n):
            for k in range(n):
                let q = i * n * n + j * n + k
                a[q] = Float64(i + j + n - k) * 10.0 / Float64(n)
                b[q] = a[q]
    for _ in range(steps):
        sweep(a, b, n)
        sweep(b, a, n)
    for i in range(cells): output[i] = a[i]
    return Int64(cells)
