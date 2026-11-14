from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import List

@export("bicg")
fn bicg(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Float64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 2: return -1.0e300
    let mv = input[0]
    let nv = input[1]
    if mv < 1 or mv > 64 or nv < 1 or nv > 64: return -1.0e300
    let m = Int(mv)
    let n = Int(nv)
    var matrix = List[Float64](capacity=4096)
    var p = List[Float64](capacity=64)
    var r = List[Float64](capacity=64)
    var s = List[Float64](capacity=64)
    var q = List[Float64](capacity=64)
    for _ in range(4096): matrix.append(0.0)
    for _ in range(64):
        p.append(0.0)
        r.append(0.0)
        s.append(0.0)
        q.append(0.0)
    for j in range(m): p[j] = Float64(j%m)/Float64(m)
    for i in range(n):
        r[i] = Float64(i%n)/Float64(n)
        for j in range(m): matrix[i*m+j] = Float64((i*(j+1))%n)/Float64(n)
    for i in range(n):
        q[i] = 0.0
        for j in range(m):
            s[j] = s[j]+r[i]*matrix[i*m+j]
            q[i] = q[i]+matrix[i*m+j]*p[j]
    var checksum = Float64(0.0)
    for j in range(m): checksum += s[j]
    for i in range(n): checksum += q[i]
    return checksum
