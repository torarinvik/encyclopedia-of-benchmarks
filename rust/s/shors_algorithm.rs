const MIN_MODULUS: i64 = 2;
const MAX_MODULUS: i64 = 255;
const MIN_ATTEMPTS: i64 = 1;
const MAX_ATTEMPTS: i64 = 16;
const INVALID_RESULT: i64 = -1;

fn gcd_i64(mut a: i64, mut b: i64) -> i64 {
    while b != 0 {
        let remainder = a % b;
        a = b;
        b = remainder;
    }
    a
}

#[no_mangle]
pub unsafe extern "C" fn shors_algorithm(packed: *const i64, length: usize) -> i64 {
    if packed.is_null() || length < 3 || length > 19 {
        return INVALID_RESULT;
    }
    let packed = std::slice::from_raw_parts(packed, length);
    let modulus = packed[0];
    let attempts = packed[1];
    if !(MIN_MODULUS..=MAX_MODULUS).contains(&modulus)
        || !(MIN_ATTEMPTS..=MAX_ATTEMPTS).contains(&attempts)
        || length != (2 + attempts) as usize
    {
        return INVALID_RESULT;
    }
    if packed[2..].iter().any(|&base| base < 2 || base > modulus) {
        return INVALID_RESULT;
    }

    for &base in &packed[2..] {
        let common = gcd_i64(base, modulus);
        if common != 1 {
            return common;
        }
        let mut order = 1i64;
        let mut power = base % modulus;
        while power != 1 && order < modulus - 1 {
            power = (power * base) % modulus;
            order += 1;
        }
        if power != 1 {
            return INVALID_RESULT;
        }
        if order % 2 == 1 {
            continue;
        }

        let mut half_power = 1i64;
        for _ in 0..order / 2 {
            half_power = (half_power * base) % modulus;
        }
        let upper = half_power + 1;
        let lower = half_power - 1;
        if upper % modulus == 0 || lower % modulus == 0 {
            continue;
        }
        let upper_gcd = gcd_i64(upper, modulus);
        if upper_gcd != 1 {
            return upper_gcd;
        }
        return gcd_i64(lower, modulus);
    }
    INVALID_RESULT
}
