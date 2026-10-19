from std.ffi import c_size_t
from std.math import exp, log, sqrt, erfc
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("black_scholes_option_price")
fn black_scholes_option_price(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Float64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 6: return -1.0e300
    let kind = input[0]; let s0 = input[1]; let k0 = input[2]; let t0 = input[3]; let vol0 = input[4]; let r0 = input[5]
    if (kind != 0 and kind != 1) or s0 < 10 or s0 > 1_000_000_000 or k0 < 10 or k0 > 1_000_000_000 or t0 < 1 or t0 > 100_000 or vol0 < 1 or vol0 > 5000 or r0 < -1000 or r0 > 1000: return -1.0e300
    let spot = Float64(s0) / 1000.0; let strike = Float64(k0) / 1000.0; let time = Float64(t0) / 1000.0
    let volatility = Float64(vol0) / 1000.0; let rate = Float64(r0) / 1000.0
    let sigma_time = volatility * sqrt(time)
    let d1 = (log(spot / strike) + (rate + volatility * volatility / 2.0) * time) / sigma_time
    let d2 = d1 - sigma_time; let sqrt_two = sqrt(2.0)
    let nd1 = 0.5 * erfc(-d1 / sqrt_two); let nd2 = 0.5 * erfc(-d2 / sqrt_two)
    let discounted = strike * exp(-rate * time)
    if kind == 0: return spot * nd1 - discounted * nd2
    return discounted * (0.5 * erfc(d2 / sqrt_two)) - spot * (0.5 * erfc(d1 / sqrt_two))
