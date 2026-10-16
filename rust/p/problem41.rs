const MAX_DIGITS: i64 = 9;

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

fn search(digits: i64, depth: i64, used: u16, value: i64) -> i64 {
    if depth == digits {
        return if is_prime(value) { value } else { 0 };
    }
    let mut best = 0i64;
    for digit in 1..=digits {
        let bit = 1u16 << digit as u32;
        if used & bit != 0 {
            continue;
        }
        let candidate = search(digits, depth + 1, used | bit, value * 10 + digit);
        best = best.max(candidate);
    }
    best
}

/// Return the largest prime formed by permuting the digits 1 through `digits`.
#[no_mangle]
pub extern "C" fn problem41(digits: i64) -> i64 {
    if !(1..=MAX_DIGITS).contains(&digits) {
        return -1;
    }
    search(digits, 0, 0, 0)
}
