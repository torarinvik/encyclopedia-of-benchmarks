from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import List

@export("two_mm")
fn two_mm(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Float64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 4: return -1.0e300
    for i in range(4):
        if input[i] < 1 or input[i] > 16: return -1.0e300
    let ni = Int(input[0])
    let nj = Int(input[1])
    let nk = Int(input[2])
    let nl = Int(input[3])
    var a = List[Float64](capacity=256)
    var b = List[Float64](capacity=256)
    var c = List[Float64](capacity=256)
    var d = List[Float64](capacity=256)
    var temporary = List[Float64](capacity=256)
    for _ in range(256):
        a.append(0.0)
        b.append(0.0)
        c.append(0.0)
        d.append(0.0)
        temporary.append(0.0)
    for i in range(ni):
        for k in range(nk): a[i*nk+k] = Float64((i*k+1)%ni)/Float64(ni)
    for k in range(nk):
        for j in range(nj): b[k*nj+j] = Float64((k*(j+1))%nj)/Float64(nj)
    for j in range(nj):
        for l in range(nl): c[j*nl+l] = Float64((j*(l+3)+1)%nl)/Float64(nl)
    for i in range(ni):
        for l in range(nl): d[i*nl+l] = Float64((i*(l+2))%nk)/Float64(nk)
    for i in range(ni):
        for j in range(nj):
            temporary[i*nj+j] = 0.0
            for k in range(nk):
                temporary[i*nj+j] += 1.5*a[i*nk+k]*b[k*nj+j]
    for i in range(ni):
        for l in range(nl):
            d[i*nl+l] *= 1.2
            for j in range(nj): d[i*nl+l] += temporary[i*nj+j]*c[j*nl+l]
    var checksum = Float64(0.0)
    for i in range(ni):
        for l in range(nl): checksum += d[i*nl+l]
    return checksum
