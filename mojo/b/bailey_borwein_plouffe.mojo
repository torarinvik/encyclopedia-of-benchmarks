from std.math import floor, pow

fn modular_power_16(exponent_value: Int64, modulus: Int64) -> Int64:
    var exponent = exponent_value
    var result = 1 % modulus
    var base = 16 % modulus
    while exponent > 0:
        if exponent & 1 != 0:
            result = (result * base) % modulus
        base = (base * base) % modulus
        exponent >>= 1
    return result

fn bbp_subsum(position: Int64, addend: Int64) -> Float64:
    var total: Float64 = 0.0
    for index in range(position + 1000):
        let denominator = 8 * index + addend
        let exponent = position - 1 - index
        var term: Float64 = 0.0
        if index < position:
            term = Float64(modular_power_16(exponent, denominator)) / Float64(denominator)
        else:
            term = pow(16.0, Float64(exponent)) / Float64(denominator)
        total += term
    return total

@export("bailey_borwein_plouffe")
fn bailey_borwein_plouffe(position: Int64) abi("C") -> Int64:
    if position < 1 or position > 10:
        return -1
    let sum_result = 4.0 * bbp_subsum(position, 1) - 2.0 * bbp_subsum(position, 4) - bbp_subsum(position, 5) - bbp_subsum(position, 6)
    let fractional = sum_result - floor(sum_result)
    return Int64(fractional * 16.0)
