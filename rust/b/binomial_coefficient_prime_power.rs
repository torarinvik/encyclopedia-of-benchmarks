const MAX_QUERIES: usize = 32;
const MAX_N: usize = 128;
const MAX_PARSEABLE: usize = 68;

fn is_prime(value: i64) -> bool {
    if value < 2 { return false; }
    let mut divisor = 2_i64;
    while divisor <= value / divisor {
        if value % divisor == 0 { return false; }
        divisor += 1;
    }
    true
}

fn pow_mod(mut base: i64, mut exponent: i64, modulus: i64) -> i64 {
    let mut result = 1_i64;
    while exponent > 0 {
        if exponent & 1 != 0 { result = result * base % modulus; }
        base = base * base % modulus;
        exponent >>= 1;
    }
    result
}

#[no_mangle]
pub unsafe extern "C" fn binomial_coefficient_prime_power(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 3 || length > MAX_PARSEABLE { return -1; }
    let p = *input;
    let e = *input.add(1);
    let q_arg = *input.add(2);
    if p < 2 || p > 31 || !is_prime(p) || !(1..=8).contains(&e) || !(0..=32).contains(&q_arg) { return -1; }
    let mut modulus = 1_i64;
    for _ in 0..e {
        modulus *= p;
        if modulus > 1_000_000_000 { return -1; }
    }
    let q = q_arg as usize;
    if length != 3 + 2 * q { return -1; }
    for index in 0..q {
        let n = *input.add(3 + 2 * index);
        let k = *input.add(4 + 2 * index);
        if n < 0 || n > MAX_N as i64 || k < 0 || k > n { return -1; }
    }
    if q == 0 { return 0; }
    let required = 4 * q;
    if output.is_null() || capacity < required { return -2; }

    let mut unit_prefix = [0_i64; MAX_N + 1];
    let mut p_free_factorial = [0_i64; MAX_N + 1];
    let mut valuation = [0_u16; MAX_N + 1];
    let mut residues = [0_u32; MAX_QUERIES];
    unit_prefix[0] = 1;
    p_free_factorial[0] = 1;
    for n in 1..=MAX_N {
        let factor = if n % p as usize == 0 { 1 } else { n as i64 };
        unit_prefix[n] = unit_prefix[n - 1] * factor % modulus;
        p_free_factorial[n] = unit_prefix[n] * p_free_factorial[n / p as usize] % modulus;
        valuation[n] = (n / p as usize + valuation[n / p as usize] as usize) as u16;
    }
    let phi = modulus / p * (p - 1);
    for index in 0..q {
        let n = *input.add(3 + 2 * index) as usize;
        let k = *input.add(4 + 2 * index) as usize;
        let p_power = (valuation[n] - valuation[k] - valuation[n - k]) as usize;
        if p_power < e as usize {
            let denominator = p_free_factorial[k] * p_free_factorial[n - k] % modulus;
            let inverse = pow_mod(denominator, phi - 1, modulus);
            let prime_factor = pow_mod(p, p_power as i64, modulus);
            residues[index] = (p_free_factorial[n] * inverse % modulus * prime_factor % modulus) as u32;
        }
    }
    for index in 0..q {
        for byte in 0..4 {
            *output.add(4 * index + byte) = (residues[index] >> (8 * byte)) as u8;
        }
    }
    required as i64
}
