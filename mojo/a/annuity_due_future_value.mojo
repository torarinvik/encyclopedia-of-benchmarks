from std.math import pow

@export("annuity_due_future_value")
fn annuity_due_future_value(payment: Float64, periods: Float64, rate: Float64) abi("C") -> Float64:
    let factor = (pow(1.0 + rate, periods) - 1.0) / rate
    return payment * factor * (1.0 + rate)
