from std.math import abs, isfinite

fn false_position_fn(x: Float64) -> Float64: return x * x - x

@export("false_position")
fn false_position(a: Float64, b: Float64) abi("C") -> Float64:
    if not isfinite(a) or not isfinite(b) or a < 0.125 or a > 0.875 or not ((b >= -2.0 and b <= -0.125) or (b >= 1.125 and b <= 3.0)): return -1.0
    var lo = a
    var hi = b
    var flo = false_position_fn(lo)
    var fhi = false_position_fn(hi)
    if not (flo < 0.0 and fhi > 0.0): return -1.0
    var c = hi
    for i in range(256):
        c = hi - fhi * (hi - lo) / (fhi - flo)
        let fc = false_position_fn(c)
        if abs(fc) <= 1e-12: return c
        if fc < 0.0:
            lo = c
            flo = fc
        else:
            hi = c
            fhi = fc
    return lo if abs(flo) <= abs(fhi) else hi
