from std.math import isfinite

@export("first_law_of_thermodynamics")
fn first_law_of_thermodynamics(operation: Float64, a: Float64, b: Float64) abi("C") -> Float64:
    if not isfinite(operation) or not isfinite(a) or not isfinite(b): return -1.0e300
    if operation < 0.0 or operation > 2.0 or operation != Float64(Int64(operation)): return -1.0e300
    if a < -1000000.0 or a > 1000000.0 or b < -1000000.0 or b > 1000000.0: return -1.0e300
    if a != Float64(Int64(a)) or b != Float64(Int64(b)): return -1.0e300
    if operation == 1.0: return a + b
    return a - b
