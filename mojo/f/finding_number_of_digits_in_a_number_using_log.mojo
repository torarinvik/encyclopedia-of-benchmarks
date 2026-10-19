from std.math import abs, floor, isfinite, log10

@export("finding_number_of_digits_in_a_number_using_log")
fn finding_number_of_digits_in_a_number_using_log(value: Float64) abi("C") -> Float64:
    if not isfinite(value) or value < -1000000.0 or value > 1000000.0: return -1.0e300
    if value == 0.0: return 0.0
    return floor(log10(abs(value)) + 1.0)
