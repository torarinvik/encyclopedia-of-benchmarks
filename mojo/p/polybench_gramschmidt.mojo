# PolyBench modified Gram-Schmidt QR with source initialization.
from std.collections import List
from std.ffi import c_size_t
from std.math import isfinite, sqrt
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("polybench_gramschmidt")
fn polybench_gramschmidt(input: UnsafePointer[Float64, ImmutAnyOrigin], length: c_size_t,
                         output: UnsafePointer[Float64, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or length != 2: return -1
    let mv = input[0]
    let nv = input[1]
    if not isfinite(mv) or not isfinite(nv) or mv < 1.0 or mv > 6.0 or nv < 1.0 or nv > mv: return -1
    let m = Int(mv)
    let n = Int(nv)
    if Float64(m) != mv or Float64(n) != nv: return -1
    let total = n*n+m*n
    var a = List[Float64](capacity=m*n)
    var q = List[Float64](capacity=m*n)
    var r = List[Float64](capacity=n*n)
    for i in range(m):
        for j in range(n):
            a.append(Float64((i*j)%m)/Float64(m)*100.0+10.0)
            q.append(0.0)
    for _ in range(n*n): r.append(0.0)
    for k in range(n):
        var norm = Float64(0.0)
        for i in range(m): norm += a[i*n+k]*a[i*n+k]
        r[k*n+k] = sqrt(norm)
        for i in range(m): q[i*n+k] = a[i*n+k]/r[k*n+k]
        for j in range(k+1,n):
            for i in range(m): r[k*n+j] += q[i*n+k]*a[i*n+j]
            for i in range(m): a[i*n+j] -= q[i*n+k]*r[k*n+j]
    if output == UnsafePointer[Float64, MutAnyOrigin]() or capacity < c_size_t(total): return -2
    for i in range(n*n): output[i] = r[i]
    for i in range(m*n): output[n*n+i] = q[i]
    return Int64(total)
