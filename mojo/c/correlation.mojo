from std.ffi import c_size_t
from std.math import sqrt
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("correlation")
fn correlation(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Float64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3: return -1.0e300
    let n = values[0]
    if n < 1 or n > 128 or length != 1 + 2 * n: return -1.0e300
    var exy: Float64 = 0.0
    var ex: Float64 = 0.0
    var exx: Float64 = 0.0
    var ey: Float64 = 0.0
    var eyy: Float64 = 0.0
    for i in range(n):
        let xi = values[1 + i]
        let yi = values[1 + n + i]
        if xi < -1000 or xi > 1000 or yi < -1000 or yi > 1000: return -1.0e300
        let x = Float64(xi)
        let y = Float64(yi)
        exy += x * y
        ex += x
        exx += x * x
        ey += y
        eyy += y * y
    exy /= Float64(n)
    ex /= Float64(n)
    exx /= Float64(n)
    ey /= Float64(n)
    eyy /= Float64(n)
    let cov = exy - ex * ey
    let varx = sqrt(exx - ex * ex)
    let vary = sqrt(eyy - ey * ey)
    if varx * vary < 1.0e-9: return 0.0
    return cov / sqrt(varx * vary)
