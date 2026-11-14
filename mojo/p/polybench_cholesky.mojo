# PolyBench source-initialized Cholesky factorization.
from std.collections import List
from std.ffi import c_size_t
from std.math import sqrt
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("polybench_cholesky")
fn polybench_cholesky(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Float64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 1: return -1.0e300
    let nv = input[0]
    if nv < 1 or nv > 64: return -1.0e300
    let n = Int(nv)
    var a = List[Float64](capacity=n*n)
    var product = List[Float64](capacity=n*n)
    for i in range(n):
        for j in range(n):
            var value = Float64(0.0)
            if j <= i: value = -Float64(j)/Float64(n)+1.0
            if i == j: value = 1.0
            a.append(value); product.append(0.0)
    for t in range(n):
        for r in range(n):
            for s in range(n): product[r*n+s] += a[r*n+t]*a[s*n+t]
    for i in range(n*n): a[i] = product[i]
    for i in range(n):
        for j in range(i):
            for k in range(j): a[i*n+j] -= a[i*n+k]*a[j*n+k]
            a[i*n+j] = a[i*n+j]/a[j*n+j]
        for k in range(i): a[i*n+i] -= a[i*n+k]*a[i*n+k]
        a[i*n+i] = sqrt(a[i*n+i])
    var total = Float64(0.0)
    for i in range(n):
        for j in range(i+1): total += a[i*n+j]
    return total
