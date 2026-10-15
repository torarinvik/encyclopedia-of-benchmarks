const MAX_INPUTS: usize = 8;
const MAX_MODULUS: i64 = 1000;

fn modular_inverse(value: i64, modulus: i64) -> i64 {
    let mut old_remainder = value % modulus;
    let mut remainder = modulus;
    let mut old_coefficient = 1_i64;
    let mut coefficient = 0_i64;
    while remainder != 0 {
        let quotient = old_remainder / remainder;
        let next_remainder = old_remainder - quotient * remainder;
        old_remainder = remainder;
        remainder = next_remainder;
        let next_coefficient = old_coefficient - quotient * coefficient;
        old_coefficient = coefficient;
        coefficient = next_coefficient;
    }
    if old_remainder != 1 { return -1; }
    old_coefficient %= modulus;
    if old_coefficient < 0 { old_coefficient += modulus; }
    old_coefficient
}

#[no_mangle]
pub unsafe extern "C" fn chinese_remainder_theorem(values: *const i64, length: usize) -> i64 {
    if length < 2 || length > MAX_INPUTS || length % 2 != 0 { return -1; }
    let mut result = 0_i64;
    let mut product = 1_i64;
    let mut index = 0;
    while index < length {
        let residue = *values.add(index);
        let modulus = *values.add(index + 1);
        if modulus < 2 || modulus > MAX_MODULUS || residue < 0 || residue >= modulus { return -1; }
        let inverse = modular_inverse(product % modulus, modulus);
        if inverse < 0 { return -1; }
        let mut difference = residue - result % modulus;
        if difference < 0 { difference += modulus; }
        let factor = (difference * inverse) % modulus;
        result += product * factor;
        product *= modulus;
        index += 2;
    }
    result
}
