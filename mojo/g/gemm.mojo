# Independent bounded implementation; see the package for PolyBench provenance.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("gemm")
fn gemm(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Float64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 3: return -1.0e300
    for i in range(3):
        if input[i] < 1 or input[i] > 64: return -1.0e300
    let ni = Int(input[0])
    let nj = Int(input[1])
    let nk = Int(input[2])
    var a = List[Float64](length=ni * nk, fill=0.0)
    var b = List[Float64](length=nk * nj, fill=0.0)
    var c = List[Float64](length=ni * nj, fill=0.0)
    for i in range(ni):
        for j in range(nj): c[i * nj + j] = Float64((i * j + 1) % ni) / Float64(ni)
    for i in range(ni):
        for k in range(nk): a[i * nk + k] = Float64((i * (k + 1)) % nk) / Float64(nk)
    for k in range(nk):
        for j in range(nj): b[k * nj + j] = Float64((k * (j + 2)) % nj) / Float64(nj)
    for i in range(ni):
        for j in range(nj): c[i * nj + j] *= 1.2
        for k in range(nk):
            for j in range(nj): c[i * nj + j] += 1.5 * a[i * nk + k] * b[k * nj + j]
    var checksum: Float64 = 0.0
    for i in range(ni):
        for j in range(nj): checksum += c[i * nj + j]
    return checksum
