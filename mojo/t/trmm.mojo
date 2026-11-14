# Bounded PolyBench TRMM profile; see package LICENSE.txt.
from std.ffi import c_size_t
from std.math import isfinite
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("trmm")
fn trmm(input: UnsafePointer[Float64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[Float64, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or length != 2: return -1
    let mv = input[0]; let nv = input[1]
    if not isfinite(mv) or not isfinite(nv) or mv < 1.0 or mv > 8.0 or nv < 1.0 or nv > 8.0: return -1
    let m = Int(mv); let n = Int(nv)
    if Float64(m) != mv or Float64(n) != nv: return -1
    if output == UnsafePointer[Float64, MutAnyOrigin]() or capacity < c_size_t(m * n): return -2
    var a = InlineArray[Float64, 64](fill=0.0)
    var b = InlineArray[Float64, 64](fill=0.0)
    for i in range(m):
        for j in range(i): a[i * m + j] = Float64((i + j) % m) / Float64(m)
        a[i * m + i] = 1.0
        for j in range(n): b[i * n + j] = Float64((n + i - j) % n) / Float64(n)
    for i in range(m):
        for j in range(n):
            for k in range(i + 1, m): b[i * n + j] += a[k * m + i] * b[k * n + j]
            b[i * n + j] *= 1.5
    for i in range(m * n): output[i] = b[i]
    return Int64(m * n)
