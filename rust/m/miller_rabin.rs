/// Deterministic Miller-Rabin for signed 32-bit inputs.
fn mod_power(mut base: i64, mut exponent: i64, modulus: i64) -> i64 {
    let mut result = 1i64;
    base %= modulus;
    while exponent > 0 {
        if exponent % 2 != 0 {
            result = (result * base) % modulus;
        }
        base = (base * base) % modulus;
        exponent /= 2;
    }
    result
}

fn passes_base(n: i64, base: i64, odd_part: i64, powers_of_two: i64) -> bool {
    let mut value = mod_power(base, odd_part, n);
    if value == 1 || value == n - 1 {
        return true;
    }
    for _ in 1..powers_of_two {
        value = (value * value) % n;
        if value == n - 1 {
            return true;
        }
    }
    false
}

#[no_mangle]
pub extern "C" fn miller_rabin(n: i64) -> i64 {
    if n < 2 {
        return 0;
    }
    if n > i32::MAX as i64 {
        return -1;
    }
    for prime in [2i64, 3, 5, 7] {
        if n == prime {
            return 1;
        }
        if n % prime == 0 {
            return 0;
        }
    }

    let mut odd_part = n - 1;
    let mut powers_of_two = 0i64;
    while odd_part % 2 == 0 {
        odd_part /= 2;
        powers_of_two += 1;
    }
    for base in [2i64, 3, 5, 7] {
        if !passes_base(n, base, odd_part, powers_of_two) {
            return 0;
        }
    }
    1
}
