# PolyBench SYMM lower-triangle update and row-major checksum.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("polybench_symm")
fn polybench_symm(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Float64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 2: return -1.0e300
    let mv = input[0]
    let nv = input[1]
    if mv < 1 or mv > 64 or nv < 1 or nv > 64: return -1.0e300
    let m = Int(mv)
    let n = Int(nv)
    var a = List[Float64](capacity=m*m)
    var b = List[Float64](capacity=m*n)
    var c = List[Float64](capacity=m*n)
    for i in range(m):
        for j in range(n):
            c.append(Float64((i+j)%100)/Float64(m))
            b.append(Float64((n+i-j)%100)/Float64(m))
    for i in range(m):
        for j in range(m):
            if j <= i: a.append(Float64((i+j)%100)/Float64(m))
            else: a.append(-999.0)
    for i in range(m):
        for j in range(n):
            var temp = Float64(0.0)
            for k in range(i):
                c[k*n+j] = c[k*n+j]+Float64(1.5)*b[i*n+j]*a[i*m+k]
                temp += b[k*n+j]*a[i*m+k]
            c[i*n+j] = Float64(1.2)*c[i*n+j]+Float64(1.5)*b[i*n+j]*a[i*m+i]+Float64(1.5)*temp
    var total = Float64(0.0)
    for i in range(m*n): total += c[i]
    return total
