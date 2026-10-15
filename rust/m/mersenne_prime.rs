fn is_prime_i64(n: i64) -> bool {
    if n < 2 {
        return false;
    }
    if n % 2 == 0 {
        return n == 2;
    }
    let mut factor = 3i64;
    while factor <= n / factor {
        if n % factor == 0 {
            return false;
        }
        factor += 2;
    }
    true
}

#[no_mangle]
pub extern "C" fn mersenne_prime(n: i64) -> i64 {
    if n == 0 {
        return 0;
    }
    if n < 0 || n > i32::MAX as i64 {
        return -1;
    }
    let mut remaining = n + 1;
    while remaining % 2 == 0 {
        remaining /= 2;
    }
    if remaining != 1 {
        return 0;
    }
    if is_prime_i64(n) { 1 } else { 0 }
}
