from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import List

@export("three_mm")
fn three_mm(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Float64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 5: return -1.0e300
    for i in range(5):
        if input[i] < 1 or input[i] > 16: return -1.0e300
    let ni = Int(input[0])
    let nj = Int(input[1])
    let nk = Int(input[2])
    let nl = Int(input[3])
    let nm = Int(input[4])
    var a = List[Float64](capacity=256)
    var b = List[Float64](capacity=256)
    var c = List[Float64](capacity=256)
    var d = List[Float64](capacity=256)
    var e = List[Float64](capacity=256)
    var f = List[Float64](capacity=256)
    var g = List[Float64](capacity=256)
    for _ in range(256):
        a.append(0.0); b.append(0.0); c.append(0.0); d.append(0.0)
        e.append(0.0); f.append(0.0); g.append(0.0)
    for i in range(ni):
        for k in range(nk): a[i*nk+k] = Float64((i*k+1)%ni)/Float64(5*ni)
    for k in range(nk):
        for j in range(nj): b[k*nj+j] = Float64((k*(j+1)+2)%nj)/Float64(5*nj)
    for i in range(nj):
        for j in range(nm): c[i*nm+j] = Float64((i*(j+3))%nl)/Float64(5*nl)
    for i in range(nm):
        for j in range(nl): d[i*nl+j] = Float64((i*(j+2)+2)%nk)/Float64(5*nk)
    for i in range(ni):
        for j in range(nj):
            for k in range(nk): e[i*nj+j] += a[i*nk+k]*b[k*nj+j]
    for i in range(nj):
        for j in range(nl):
            for k in range(nm): f[i*nl+j] += c[i*nm+k]*d[k*nl+j]
    for i in range(ni):
        for j in range(nl):
            for k in range(nj): g[i*nl+j] += e[i*nj+k]*f[k*nl+j]
    var checksum = Float64(0.0)
    for i in range(ni):
        for j in range(nl): checksum += g[i*nl+j]
    return checksum
