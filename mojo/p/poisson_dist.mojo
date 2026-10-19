from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn poisson_point(mean: Float64, k: Int64) -> Float64:
    var power = 1.0
    var fact = 1.0
    for i in range(Int(k)):
        power *= mean
        fact *= Float64(i + 1)
    var e = 1.0
    var term = 1.0
    for i in range(1, 100):
        term *= -mean / Float64(i)
        e += term
        if term > -1.0e-17 and term < 1.0e-17: break
    return power * e / fact

@export("poisson_dist")
fn poisson_dist(v: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t) abi("C") -> Float64:
    if v == UnsafePointer[Int64, ImmutAnyOrigin]() or n != 4: return -1.0e300
    let op = v[0]; let a = v[1]; let b = v[2]; let c = v[3]
    if op == 0:
        if a < 0 or a > 100000 or b < 1 or b > 100000 or c != 0: return -1.0e300
        return Float64(a) / Float64(b)
    if op == 1:
        if a < 0 or a > 100000 or b < 0 or b > 100000 or c != 0: return -1.0e300
        return (Float64(a) * Float64(b)) / 1000000.0
    if op == 2:
        if a < 0 or a > 100000 or b < 0 or b > 20 or c != 0: return -1.0e300
        return poisson_point(Float64(a) / 1000.0, b)
    if op == 3:
        if a < 0 or a > 100000 or b < 0 or b > c or c > 20: return -1.0e300
        var result = 0.0
        for k in range(Int(b), Int(c) + 1): result += poisson_point(Float64(a) / 1000.0, Int64(k))
        return result
    return -1.0e300
