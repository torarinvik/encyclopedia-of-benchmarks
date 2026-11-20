fn gcd_i64(mut a: i64, mut b: i64) -> i64 {
    while b != 0 { let remainder = a % b; a = b; b = remainder; }
    a
}

fn pow_mod_i64(base_input: i64, mut exponent: i64, modulus: i64) -> i64 {
    let mut base = base_input % modulus;
    let mut result = 1i64;
    while exponent > 0 {
        if exponent % 2 != 0 { result = result * base % modulus; }
        base = base * base % modulus;
        exponent /= 2;
    }
    result
}

fn totient_i64(value: i64) -> i64 {
    let mut remaining = value;
    let mut result = value;
    let mut prime = 2i64;
    while prime * prime <= remaining {
        if remaining % prime == 0 {
            result = result / prime * (prime - 1);
            while remaining % prime == 0 { remaining /= prime; }
        }
        prime += 1;
    }
    if remaining > 1 { result = result / remaining * (remaining - 1); }
    result
}

fn reduce_order(base: i64, modulus: i64, initial_order: i64) -> i64 {
    let mut remaining = initial_order;
    let mut order = initial_order;
    let mut prime = 2i64;
    while prime * prime <= remaining {
        if remaining % prime == 0 {
            while remaining % prime == 0 { remaining /= prime; }
            while order % prime == 0 && pow_mod_i64(base, order / prime, modulus) == 1 {
                order /= prime;
            }
        }
        prime += 1;
    }
    if remaining > 1 {
        while order % remaining == 0 && pow_mod_i64(base, order / remaining, modulus) == 1 {
            order /= remaining;
        }
    }
    order
}

#[no_mangle]
pub unsafe extern "C" fn multiplicative_order(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != 2 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let (base, modulus) = (values[0], values[1]);
    if modulus < 2 || modulus > 1000 || base < 0 || base >= modulus { return -1; }
    if gcd_i64(base, modulus) != 1 { return 0; }
    reduce_order(base, modulus, totient_i64(modulus))
}
