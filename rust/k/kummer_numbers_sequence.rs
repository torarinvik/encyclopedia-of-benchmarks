fn is_prime(value: i64) -> bool {
    if value < 2 {
        return false;
    }
    let mut factor = 2i64;
    while factor <= value / factor {
        if value % factor == 0 {
            return false;
        }
        factor += 1;
    }
    true
}

#[no_mangle]
pub extern "C" fn kummer_numbers_sequence(index: i64) -> i64 {
    if !(0..=14).contains(&index) {
        return -1;
    }
    let mut product = 1i64;
    let mut prime_count = 0i64;
    let mut candidate = 2i64;
    while prime_count < index + 1 {
        if is_prime(candidate) {
            product *= candidate;
            prime_count += 1;
        }
        candidate += 1;
    }
    product - 1
}
