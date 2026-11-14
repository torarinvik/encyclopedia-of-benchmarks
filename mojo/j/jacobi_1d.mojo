# Independent bounded stencil implementation; see the package license.
from std.collections import List
from std.ffi import c_size_t
from std.math import isfinite
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("jacobi_1d")
fn jacobi_1d(input: UnsafePointer[Float64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[Float64, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or length != 2: return -1
    let nv = input[0]; let tv = input[1]
    if not isfinite(nv) or not isfinite(tv) or nv < 1.0 or nv > 30.0 or tv < 0.0 or tv > 20.0: return -1
    let n = Int(nv); let steps = Int(tv)
    if Float64(n) != nv or Float64(steps) != tv: return -1
    if output == UnsafePointer[Float64, MutAnyOrigin]() or capacity < c_size_t(n): return -2
    var a = List[Float64](length=n, fill=0.0)
    var b = List[Float64](length=n, fill=0.0)
    for i in range(n):
        a[i] = (Float64(i) + 2.0) / Float64(n)
        b[i] = (Float64(i) + 3.0) / Float64(n)
    for _ in range(steps):
        if n > 2:
            for i in range(1, n - 1): b[i] = 0.33333 * (a[i - 1] + a[i] + a[i + 1])
            for i in range(1, n - 1): a[i] = 0.33333 * (b[i - 1] + b[i] + b[i + 1])
    for i in range(n): output[i] = a[i]
    return Int64(n)
