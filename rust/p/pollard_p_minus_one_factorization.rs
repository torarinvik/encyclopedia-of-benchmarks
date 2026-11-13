const SMALL_PRIMES: [i64; 18] = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61];

fn gcd_i64(mut left: i64, mut right: i64) -> i64 {
    while right != 0 {
        let remainder = left % right;
        left = right;
        right = remainder;
    }
    left
}

fn pow_mod_i64(base_input: i64, exponent_input: i64, modulus: i64) -> i64 {
    let mut result = 1i64;
    let mut base = base_input % modulus;
    let mut exponent = exponent_input;
    while exponent > 0 {
        if exponent & 1 != 0 { result = (result * base) % modulus; }
        base = (base * base) % modulus;
        exponent >>= 1;
    }
    result
}

#[no_mangle]
pub unsafe extern "C" fn pollard_p_minus_one_factorization(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != 3 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let (number, bound, initial) = (values[0], values[1], values[2]);
    if number < 2 || number > 1_000_000_000 || bound < 2 || bound > 64 || initial < 1 || initial >= number { return -1; }
    let mut divisor = gcd_i64(initial, number);
    if divisor > 1 { return divisor; }
    let mut state = initial;
    for &prime in &SMALL_PRIMES {
        if prime > bound { break; }
        let mut exponent = prime;
        while exponent <= bound / prime { exponent *= prime; }
        state = pow_mod_i64(state, exponent, number);
        divisor = gcd_i64((state - 1).abs(), number);
        if divisor > 1 { return if divisor < number { divisor } else { 0 }; }
    }
    0
}
