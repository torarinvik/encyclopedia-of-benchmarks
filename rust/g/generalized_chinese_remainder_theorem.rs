const MAX_PRODUCT: i64 = 16_777_216;

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
    old_coefficient %= modulus;
    if old_coefficient < 0 { old_coefficient += modulus; }
    old_coefficient
}

#[no_mangle]
pub unsafe extern "C" fn generalized_chinese_remainder_theorem(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 1 || length > 10 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let count = values[0];
    if count < 1 || count > 4 || length != (1 + 2 * count) as usize { return -1; }
    let mut product = 1_i64;
    for index in 0..count as usize {
        let residue = values[1 + 2 * index];
        let modulus = values[2 + 2 * index];
        if modulus < 2 || modulus > 64 || residue < 0 || residue >= modulus { return -1; }
        if product > MAX_PRODUCT / modulus { return -1; }
        product *= modulus;
    }

    let mut powers = [0_i64; 65];
    let mut residues = [0_i64; 65];
    for index in 0..count as usize {
        let residue = values[1 + 2 * index];
        let mut remaining = values[2 + 2 * index];
        let mut prime = 2_i64;
        while prime <= remaining {
            if remaining % prime == 0 {
                let mut prime_power = 1_i64;
                while remaining % prime == 0 {
                    remaining /= prime;
                    prime_power *= prime;
                }
                let slot = prime as usize;
                if prime_power > powers[slot] {
                    powers[slot] = prime_power;
                    residues[slot] = residue % prime_power;
                }
            }
            prime += 1;
        }
    }
    for index in 0..count as usize {
        let residue = values[1 + 2 * index];
        let mut remaining = values[2 + 2 * index];
        let mut prime = 2_i64;
        while prime <= remaining {
            if remaining % prime == 0 {
                let mut prime_power = 1_i64;
                while remaining % prime == 0 {
                    remaining /= prime;
                    prime_power *= prime;
                }
                let slot = prime as usize;
                if residues[slot] % prime_power != residue % prime_power { return -2; }
            }
            prime += 1;
        }
    }

    let mut solution = 0_i64;
    let mut combined_modulus = 1_i64;
    for prime in 2..=64 {
        let modulus = powers[prime];
        if modulus == 0 { continue; }
        let inverse = modular_inverse(combined_modulus % modulus, modulus);
        let mut difference = (residues[prime] - solution % modulus) % modulus;
        if difference < 0 { difference += modulus; }
        let multiplier = difference * inverse % modulus;
        solution += combined_modulus * multiplier;
        combined_modulus *= modulus;
        solution %= combined_modulus;
    }
    solution
}
