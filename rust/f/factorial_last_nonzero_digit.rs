fn digit_factor(digit: i64) -> i64 {
    match digit {
        0 | 1 => 1,
        2 => 2,
        3 => 6,
        _ => 4,
    }
}

fn two_power_mod_10(exponent_mod_four: i64) -> i64 {
    match exponent_mod_four {
        0 => 1,
        1 => 2,
        2 => 4,
        _ => 8,
    }
}

#[no_mangle]
pub unsafe extern "C" fn factorial_last_nonzero_digit(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(1..=2).contains(&length) {
        return -1;
    }
    if length != 1 {
        return -1;
    }
    let n_value = *input;
    if n_value < 0 {
        return -1;
    }

    let mut n = n_value;
    let mut result = 1_i64;
    while n >= 5 {
        let quotient = n / 5;
        let remainder = n % 5;
        result = result * digit_factor(remainder) % 10;
        result = result * two_power_mod_10(quotient % 4) % 10;
        n = quotient;
    }
    result * digit_factor(n) % 10
}
