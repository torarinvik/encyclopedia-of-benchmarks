const MAX_MULTIPLIER: i64 = 950_560;

fn is_prime(value: i64) -> bool {
    if value < 2 {
        return false;
    }
    let mut divisor = 2i64;
    while divisor <= value / divisor {
        if value % divisor == 0 {
            return false;
        }
        divisor += 1;
    }
    true
}

fn all_chernick_factors_are_prime(n: i64, multiplier: i64) -> bool {
    if !is_prime(6 * multiplier + 1) || !is_prime(12 * multiplier + 1) {
        return false;
    }

    let mut factor = 18 * multiplier + 1;
    let mut index = 1i64;
    while index <= n - 2 {
        if !is_prime(factor) {
            return false;
        }
        if index < n - 2 {
            factor = 2 * (factor - 1) + 1;
        }
        index += 1;
    }
    true
}

#[no_mangle]
pub unsafe extern "C" fn chernick_carmichael_least_multiplier(
    input: *const i64,
    length: usize,
) -> i64 {
    if input.is_null() || length != 1 {
        return -1;
    }
    let n = *input;
    if !(3..=9).contains(&n) {
        return -1;
    }

    let mut step = 1i64;
    if n > 4 {
        let mut shifts = n - 4;
        while shifts > 0 {
            step *= 2;
            shifts -= 1;
        }
    }
    if n > 5 {
        step *= 5;
    }

    let mut multiplier = step;
    while multiplier <= MAX_MULTIPLIER {
        if all_chernick_factors_are_prime(n, multiplier) {
            return multiplier;
        }
        multiplier += step;
    }
    -1
}
