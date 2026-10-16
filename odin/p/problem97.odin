// Return the unpadded decimal suffix of the non-Mersenne prime expression.
package problem97

MAX_DIGITS :: i64(18)
POWER_EXPONENT :: i64(7_830_457)

multiply_mod :: proc(left_value, right_value, modulus: i64) -> i64 {
    left := left_value
    right := right_value
    result_value: i64 = 0
    for right > 0 {
        if right % 2 != 0 { result_value = (result_value + left) % modulus }
        left = (left + left) % modulus
        right /= 2
    }
    return result_value
}

@(export)
problem97 :: proc "c" (digits: i64) -> i64 {
    if digits < 0 || digits > MAX_DIGITS do return -1
    modulus: i64 = 1
    for index := i64(0); index < digits; index += 1 { modulus *= 10 }
    power := i64(1) % modulus
    base := i64(2) % modulus
    exponent := POWER_EXPONENT
    for exponent > 0 {
        if exponent % 2 != 0 { power = multiply_mod(power, base, modulus) }
        base = multiply_mod(base, base, modulus)
        exponent /= 2
    }
    return (multiply_mod(28_433, power, modulus) + 1) % modulus
}
