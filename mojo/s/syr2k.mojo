# Bounded PolyBench SYR2K profile; see package LICENSE.txt.
from std.ffi import c_size_t
from std.math import isfinite
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("syr2k")
fn syr2k(input: UnsafePointer[Float64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[Float64, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or length != 2: return -1
    let nv = input[0]
    let mv = input[1]
    if not isfinite(nv) or not isfinite(mv) or nv < 1.0 or nv > 8.0 or mv < 1.0 or mv > 16.0: return -1
    let n = Int(nv)
    let m = Int(mv)
    if Float64(n) != nv or Float64(m) != mv: return -1
    if output == UnsafePointer[Float64, MutAnyOrigin]() or capacity < c_size_t(n * n): return -2
    var a = InlineArray[Float64, 128](fill=0.0)
    var b = InlineArray[Float64, 128](fill=0.0)
    var c = InlineArray[Float64, 64](fill=0.0)
    for i in range(n):
        for j in range(m):
            a[i * m + j] = Float64((i * j + 1) % n) / Float64(n)
            b[i * m + j] = Float64((i * j + 2) % m) / Float64(m)
    for i in range(n):
        for j in range(n): c[i * n + j] = Float64((i * j + 3) % n) / Float64(m)
    for i in range(n):
        for j in range(i + 1): c[i * n + j] *= 1.2
        for k in range(m):
            for j in range(i + 1):
                c[i * n + j] += a[j * m + k] * 1.5 * b[i * m + k] + b[j * m + k] * 1.5 * a[i * m + k]
    for i in range(n * n): output[i] = c[i]
    return Int64(n * n)
