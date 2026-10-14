module modular_exponentiation

// Binary exponentiation under a positive signed 32-bit modulus.
@[export: 'modular_exponentiation']
pub fn modular_exponentiation(values &i64, length usize) i64 {
    if length != 3 { return -1 }
    base_input := unsafe { values[0] }
    exponent_input := unsafe { values[1] }
    modulus := unsafe { values[2] }
    if base_input < -2147483648 || base_input > 2147483647 || exponent_input < 0 ||
        exponent_input > 2147483647 || modulus < 1 || modulus > 2147483647 { return -1 }
    mut base := base_input % modulus
    if base < 0 { base += modulus }
    mut exponent := u64(exponent_input)
    mut result := i64(1) % modulus
    for exponent != 0 {
        if exponent & 1 != 0 { result = (result * base) % modulus }
        base = (base * base) % modulus
        exponent >>= 1
    }
    return result
}
