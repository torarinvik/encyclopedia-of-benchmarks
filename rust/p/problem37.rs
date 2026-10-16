fn is_prime(value: i64) -> bool {
    if value < 2 {
        return false;
    }
    if value == 2 || value == 3 {
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

fn is_truncatable_prime(value: i64) -> bool {
    if !is_prime(value) {
        return false;
    }
    let mut power = 10;
    while power < value {
        if !is_prime(value / power) || !is_prime(value % power) {
            return false;
        }
        power *= 10;
    }
    true
}

/// Sum the eleven primes truncatable from both directions.
#[no_mangle]
pub extern "C" fn problem37(ignored: i64) -> i64 {
    if ignored != 0 {
        return -1;
    }
    let mut found = 0;
    let mut sum = 0_i64;
    let mut candidate = 13_i64;
    while candidate <= 1_000_000 && found < 11 {
        if is_truncatable_prime(candidate) {
            sum += candidate;
            found += 1;
        }
        candidate += 2;
    }
    if found == 11 { sum } else { -1 }
}
