from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import List

@export("atax")
fn atax(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Float64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 2: return -1.0e300
    let mv = input[0]
    let nv = input[1]
    if mv < 1 or mv > 64 or nv < 1 or nv > 64: return -1.0e300
    let m = Int(mv)
    let n = Int(nv)
    var matrix = List[Float64](capacity=4096)
    var x = List[Float64](capacity=64)
    var y = List[Float64](capacity=64)
    var temporary = List[Float64](capacity=64)
    for _ in range(4096): matrix.append(0.0)
    for _ in range(64):
        x.append(0.0)
        y.append(0.0)
        temporary.append(0.0)
    for j in range(n): x[j] = 1.0+Float64(j)/Float64(n)
    for i in range(m):
        for j in range(n): matrix[i*n+j] = Float64((i+j)%n)/Float64(5*m)
    for i in range(m):
        temporary[i] = 0.0
        for j in range(n): temporary[i] = temporary[i]+matrix[i*n+j]*x[j]
        for j in range(n): y[j] = y[j]+matrix[i*n+j]*temporary[i]
    var checksum = Float64(0.0)
    for j in range(n): checksum += y[j]
    return checksum
