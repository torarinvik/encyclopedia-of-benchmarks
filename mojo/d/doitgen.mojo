# Independent bounded PolyBench doitgen profile; see package license.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("doitgen")
fn doitgen(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Float64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 3: return -1.0e300
    for i in range(3):
        if values[i] < 1 or values[i] > 16: return -1.0e300
    let nr = Int(values[0])
    let nq = Int(values[1])
    let np = Int(values[2])
    var a = List[Float64](capacity=nr*nq*np)
    var c = List[Float64](capacity=np*np)
    var sums = List[Float64](capacity=np)
    for r in range(nr):
        for q in range(nq):
            for p in range(np): a.append(Float64((r*q+p) % np) / Float64(np))
    for i in range(np):
        for j in range(np): c.append(Float64((i*j) % np) / Float64(np))
    for _ in range(np): sums.append(0.0)
    for r in range(nr):
        for q in range(nq):
            let base = (r*nq+q)*np
            for p in range(np):
                var value = Float64(0.0)
                for s in range(np): value += a[base+s] * c[s*np+p]
                sums[p] = value
            for p in range(np): a[base+p] = sums[p]
    var checksum = Float64(0.0)
    for i in range(nr*nq*np): checksum += a[i]
    return checksum
