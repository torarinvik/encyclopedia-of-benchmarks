# Independent bounded PolyBench covariance profile; see package license.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("covariance")
fn covariance(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Float64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 2: return -1.0e300
    if values[0] < 2 or values[0] > 64 or values[1] < 1 or values[1] > 64: return -1.0e300
    let n = Int(values[0])
    let m = Int(values[1])
    var data = List[Float64](capacity=n*m)
    var means = List[Float64](capacity=m)
    var cov = List[Float64](capacity=m*m)
    for i in range(n):
        for j in range(m): data.append((Float64(i) * Float64(j)) / Float64(m))
    for _ in range(m): means.append(0.0)
    for _ in range(m*m): cov.append(0.0)
    for j in range(m):
        for i in range(n): means[j] += data[i*m+j]
        means[j] /= Float64(n)
    for i in range(n):
        for j in range(m): data[i*m+j] -= means[j]
    for i in range(m):
        for j in range(i, m):
            var sum = Float64(0.0)
            for k in range(n): sum += data[k*m+i] * data[k*m+j]
            let value = sum / Float64(n-1)
            cov[i*m+j] = value
            cov[j*m+i] = value
    var checksum = Float64(0.0)
    for i in range(m):
        for j in range(m): checksum += cov[i*m+j]
    return checksum
