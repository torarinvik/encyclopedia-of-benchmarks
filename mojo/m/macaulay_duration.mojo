from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.math import pow

@export("macaulay_duration")
fn macaulay_duration(v: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t) abi("C") -> Float64:
    if v == UnsafePointer[Int64, ImmutAnyOrigin]() or n != 4: return -1.0e300
    let face = v[0]; let coupon = v[1]; let periods = v[2]; let yield = v[3]
    if face < 1 or face > 1_000_000_000_000 or coupon < 0 or coupon > 1_000_000 or periods < 1 or periods > 64 or yield < 1 or yield > 1_000_000: return -1.0e300
    let face_value = Float64(face) / 1_000_000.0
    let coupon_rate = Float64(coupon) / 1_000_000.0
    let yield_rate = Float64(yield) / 1_000_000.0
    var pv = 0.0; var weighted = 0.0
    for t in range(1, Int(periods) + 1):
        let cash = face_value * coupon_rate + (face_value if t == Int(periods) else 0.0)
        let discount = pow(1.0 + yield_rate, Float64(t))
        weighted += (Float64(t) * cash) / discount
        pv += cash / discount
    return weighted / pv
