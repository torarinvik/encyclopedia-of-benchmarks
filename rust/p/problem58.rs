fn is_prime(value: i64) -> bool {
    if value < 2 {
        return false;
    }
    if value < 4 {
        return true;
    }
    if value % 2 == 0 || value % 3 == 0 {
        return false;
    }
    let mut divisor = 5;
    while divisor <= value / divisor {
        if value % divisor == 0 || value % (divisor + 2) == 0 {
            return false;
        }
        divisor += 6;
    }
    true
}

/// Return the first spiral side length below the requested diagonal prime ratio.
#[no_mangle]
pub extern "C" fn problem58(ratio: f64) -> f64 {
    if !(0.1..=0.6).contains(&ratio) {
        return -1.0;
    }
    let mut side = 3_i64;
    let mut prime_count = 3_i64;
    while prime_count as f64 / (2 * side - 1) as f64 >= ratio {
        let square = side * side;
        let step = side + 1;
        if is_prime(square + step) { prime_count += 1; }
        if is_prime(square + 2 * step) { prime_count += 1; }
        if is_prime(square + 3 * step) { prime_count += 1; }
        side += 2;
    }
    side as f64
}
