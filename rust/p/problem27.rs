fn problem27_is_prime(value: i64) -> bool {
    if value < 2 {
        return false;
    }
    if value % 2 == 0 {
        return value == 2;
    }
    if value % 3 == 0 {
        return value == 3;
    }
    let mut factor = 5;
    while factor <= value / factor {
        if value % factor == 0 || value % (factor + 2) == 0 {
            return false;
        }
        factor += 6;
    }
    true
}

/// Return the coefficient product with the longest prime-producing run.
#[no_mangle]
pub extern "C" fn problem27(limit: i64) -> i64 {
    if !(1..=1000).contains(&limit) {
        return -1;
    }
    let mut best_length = 0;
    let mut best_a = 0;
    let mut best_b = 0;
    for a in (1 - limit)..limit {
        for b in 2..limit {
            if !problem27_is_prime(b) {
                continue;
            }
            let mut n = 0;
            while problem27_is_prime(n * n + a * n + b) {
                n += 1;
            }
            if n > best_length {
                best_length = n;
                best_a = a;
                best_b = b;
            }
        }
    }
    best_a * best_b
}
