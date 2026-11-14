from std.ffi import c_size_t
from std.math import cos, isfinite, sin, sqrt
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("partialsums")
fn partialsums(input: UnsafePointer[Float64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[Float64, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or length != 1: return -1
    let raw = input[0]
    if not isfinite(raw) or raw < 1.0 or raw > 10000.0: return -1
    let n = Int(raw)
    if Float64(n) != raw: return -1
    if output == UnsafePointer[Float64, MutAnyOrigin]() or capacity < 9: return -2
    var geometric: Float64 = 0.0
    var inverse_sqrt: Float64 = 0.0
    var flint: Float64 = 0.0
    var cookson: Float64 = 0.0
    var telescoping = InlineArray[Float64, 2](fill=0.0)
    var harmonic = InlineArray[Float64, 2](fill=0.0)
    var zeta = InlineArray[Float64, 2](fill=0.0)
    var alternating = InlineArray[Float64, 2](fill=0.0)
    var gregory = InlineArray[Float64, 2](fill=0.0)
    var term: Float64 = 1.0
    let limit = n + (n & 1)
    for k in range(1, limit + 1):
        let kd = Float64(k)
        let lane = (k - 1) & 1
        if k <= n:
            let cube = kd * kd * kd
            let s = sin(kd)
            let c = cos(kd)
            geometric += term
            term *= 2.0 / 3.0
            inverse_sqrt += 1.0 / sqrt(kd)
            flint += 1.0 / (cube * s * s)
            cookson += 1.0 / (cube * c * c)
        telescoping[lane] += 1.0 / (kd * (kd + 1.0))
        harmonic[lane] += 1.0 / kd
        zeta[lane] += 1.0 / (kd * kd)
        let sign: Float64 = if lane == 0: 1.0 else: -1.0
        alternating[lane] += sign / kd
        gregory[lane] += sign / (2.0 * kd - 1.0)
    output[0] = geometric
    output[1] = inverse_sqrt
    output[2] = telescoping[0] + telescoping[1]
    output[3] = flint
    output[4] = cookson
    output[5] = harmonic[0] + harmonic[1]
    output[6] = zeta[0] + zeta[1]
    output[7] = alternating[0] + alternating[1]
    output[8] = gregory[0] + gregory[1]
    return 9
