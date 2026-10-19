from std.math import isfinite, pow
@export("sum_of_geometric_progression")
fn sum_of_geometric_progression(first: Float64, ratio: Float64, terms: Float64) abi("C") -> Float64:
    if not isfinite(first) or not isfinite(ratio) or not isfinite(terms): return -1.0e300
    if first < -1000.0 or first > 1000.0 or ratio < -2.0 or ratio > 2.0: return -1.0e300
    if terms < 0.0 or terms > 16.0 or Float64(Int(terms)) != terms: return -1.0e300
    if ratio > 0.9 and ratio < 1.1 and ratio != 1.0: return -1.0e300
    if ratio == 1.0: return terms * first
    return (first / (1.0-ratio)) * (1.0-pow(ratio, Int(terms)))
