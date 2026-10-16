const MAX_ODD_COMPOSITE: i64 = 99_999;

fn is_prime(number: i64) -> bool {
    if number < 2 {
        return false;
    }
    if number < 4 {
        return true;
    }
    if number % 2 == 0 || number % 3 == 0 {
        return false;
    }
    let mut divisor = 5i64;
    while divisor <= number / divisor {
        if number % divisor == 0 || number % (divisor + 2) == 0 {
            return false;
        }
        divisor += 6;
    }
    true
}

fn find_first_counterexample() -> i64 {
    let mut candidate = 3i64;
    while candidate <= MAX_ODD_COMPOSITE {
        if !is_prime(candidate) {
            let mut represented = false;
            let mut square = 0i64;
            while 2 * square * square <= candidate {
                if is_prime(candidate - 2 * square * square) {
                    represented = true;
                    break;
                }
                square += 1;
            }
            if !represented {
                return candidate;
            }
        }
        candidate += 2;
    }
    -1
}

/// Run the pinned no-argument search when the placeholder is zero.
#[no_mangle]
pub extern "C" fn problem46(placeholder: i64) -> i64 {
    if placeholder != 0 {
        return -1;
    }
    find_first_counterexample()
}
