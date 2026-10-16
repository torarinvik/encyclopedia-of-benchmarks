fn normalized_mod(value: i64, modulus: i64) -> i64 {
    let remainder = value % modulus;
    if remainder < 0 { remainder + modulus } else { remainder }
}

#[no_mangle]
pub extern "C" fn modular_inverse(a: i64, modulus: i64) -> i64 {
    if a < 0 || a > 1_000_000 || modulus < 2 || modulus > 1_000_000 {
        return -1;
    }

    let mut old_remainder = normalized_mod(a, modulus);
    let mut remainder = modulus;
    let mut old_coefficient = 1_i64;
    let mut coefficient = 0_i64;
    while remainder != 0 {
        let quotient = old_remainder / remainder;
        let next_remainder = old_remainder - quotient * remainder;
        let next_coefficient = old_coefficient - quotient * coefficient;
        old_remainder = remainder;
        remainder = next_remainder;
        old_coefficient = coefficient;
        coefficient = next_coefficient;
    }
    if old_remainder != 1 { return -1; }
    normalized_mod(old_coefficient, modulus)
}
