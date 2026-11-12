from std.ffi import c_size_t
from std.math import isfinite, sqrt
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn in_range(value: Float64, minimum: Float64, maximum: Float64) -> Bool:
    return isfinite(value) and value >= minimum and value <= maximum

@export("hjm_forward_path")
fn hjm_forward_path(
    input: UnsafePointer[Float64, ImmutAnyOrigin], input_length: c_size_t,
    output: UnsafePointer[Float64, MutAnyOrigin], output_capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or input_length < 7 or input_length > 54:
        return -1
    for index in range(Int(input_length)):
        if not isfinite(input[index]):
            return -1
    let steps_value = input[0]
    let factors_value = input[1]
    if not in_range(steps_value, 2.0, 8.0) or not in_range(factors_value, 1.0, 3.0):
        return -1
    if Float64(Int(steps_value)) != steps_value or Float64(Int(factors_value)) != factors_value:
        return -1
    let steps = Int(steps_value)
    let factors = Int(factors_value)
    let years = input[2]
    if years != 1.0 and years != 2.0 and years != 3.0:
        return -1
    let expected = 3 + steps + 2 * factors * (steps - 1)
    if Int(input_length) != expected:
        return -1

    var yields = InlineArray[Float64, 8](fill=0.0)
    var vols = InlineArray[Float64, 21](fill=0.0)
    var shocks = InlineArray[Float64, 21](fill=0.0)
    var forwards = InlineArray[Float64, 8](fill=0.0)
    var factor_drifts = InlineArray[Float64, 21](fill=0.0)
    var total_drifts = InlineArray[Float64, 7](fill=0.0)
    var path = InlineArray[Float64, 64](fill=0.0)

    var cursor = 3
    for maturity in range(steps):
        let value = input[cursor]
        cursor += 1
        if not in_range(value, -0.05, 0.20):
            return -1
        yields[maturity] = value
    for factor in range(factors):
        for maturity in range(steps - 1):
            let value = input[cursor]
            cursor += 1
            if not in_range(value, 0.0, 0.30):
                return -1
            vols[factor * 7 + maturity] = value
    for time in range(steps - 1):
        for factor in range(factors):
            let value = input[cursor]
            cursor += 1
            if not in_range(value, -3.0, 3.0):
                return -1
            shocks[time * 3 + factor] = value

    let dt = years / Float64(steps)
    forwards[0] = yields[0]
    for maturity in range(1, steps):
        forwards[maturity] = Float64(maturity + 1) * yields[maturity] - Float64(maturity) * yields[maturity - 1]
    for factor in range(factors):
        factor_drifts[factor * 7] = 0.5 * dt * vols[factor * 7] * vols[factor * 7]
        for maturity in range(1, steps - 1):
            var drift: Float64 = 0.0
            for prior in range(maturity):
                drift -= factor_drifts[factor * 7 + prior]
            var prefix_volatility: Float64 = 0.0
            for prior in range(maturity + 1):
                prefix_volatility += vols[factor * 7 + prior]
            drift += 0.5 * dt * prefix_volatility * prefix_volatility
            factor_drifts[factor * 7 + maturity] = drift
    for maturity in range(steps - 1):
        for factor in range(factors):
            total_drifts[maturity] += factor_drifts[factor * 7 + maturity]
    for maturity in range(steps):
        path[maturity] = forwards[maturity]
    let root_dt = sqrt(dt)
    for time in range(1, steps):
        for maturity in range(steps - time):
            var total_shock: Float64 = 0.0
            for factor in range(factors):
                total_shock += vols[factor * 7 + maturity] * shocks[(time - 1) * 3 + factor]
            path[time * steps + maturity] = path[(time - 1) * steps + maturity + 1] + total_drifts[maturity] * dt + root_dt * total_shock

    let needed = steps * steps
    if output == UnsafePointer[Float64, MutAnyOrigin]() or Int(output_capacity) < needed:
        return -2
    for index in range(needed):
        output[index] = path[index]
    return Int64(needed)
