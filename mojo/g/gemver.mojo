# Independent bounded implementation; see the package for PolyBench provenance.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("gemver")
fn gemver(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Float64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 1: return -1.0e300
    let n0 = input[0]
    if n0 < 1 or n0 > 64: return -1.0e300
    let n = Int(n0)
    let size = Float64(n)
    var a = List[Float64](length=n * n, fill=0.0)
    var u1 = List[Float64](length=n, fill=0.0)
    var u2 = List[Float64](length=n, fill=0.0)
    var v1 = List[Float64](length=n, fill=0.0)
    var v2 = List[Float64](length=n, fill=0.0)
    var x = List[Float64](length=n, fill=0.0)
    var y = List[Float64](length=n, fill=0.0)
    var z = List[Float64](length=n, fill=0.0)
    var w = List[Float64](length=n, fill=0.0)
    for i in range(n):
        let fraction = Float64(i + 1) / size
        u1[i] = Float64(i)
        u2[i] = fraction / 2.0
        v1[i] = fraction / 4.0
        v2[i] = fraction / 6.0
        y[i] = fraction / 8.0
        z[i] = fraction / 9.0
        for j in range(n): a[i * n + j] = Float64((i * j) % n) / size
    for i in range(n):
        for j in range(n):
            let k = i * n + j
            a[k] = a[k] + u1[i] * v1[j] + u2[i] * v2[j]
    for i in range(n):
        for j in range(n): x[i] = x[i] + 1.2 * a[j * n + i] * y[j]
    for i in range(n): x[i] = x[i] + z[i]
    for i in range(n):
        for j in range(n): w[i] = w[i] + 1.5 * a[i * n + j] * x[j]
    var checksum: Float64 = 0.0
    for i in range(n): checksum += w[i]
    return checksum
