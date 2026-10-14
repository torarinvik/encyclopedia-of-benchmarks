module binary_exponentiation

// Exponentiation by squaring with exact signed i64 overflow detection.
@[export: 'binary_exponentiation']
pub fn binary_exponentiation(values &i64, length usize) i64 {
    if length != 2 { return -1 }
    base_input := unsafe { values[0] }
    exponent_input := unsafe { values[1] }
    if base_input < 0 || base_input > 2147483647 || exponent_input < 0 || exponent_input > 2147483647 { return -1 }
    mut base := u64(base_input)
    mut exponent := u64(exponent_input)
    mut result := u64(1)
    maximum := u64(9223372036854775807)
    for exponent != 0 {
        if exponent & 1 != 0 {
            if base != 0 && result > maximum / base { return -1 }
            result *= base
        }
        exponent >>= 1
        if exponent != 0 {
            if base != 0 && base > maximum / base { return -1 }
            base *= base
        }
    }
    return i64(result)
}
