const MAX_PARSEABLE_LENGTH: usize = 2;
const MAX_N: i64 = 8;

fn least_prime_factor(value: i64) -> i64 {
    let mut divisor = 2_i64;
    while divisor <= value / divisor {
        if value % divisor == 0 {
            return divisor;
        }
        divisor += 1;
    }
    value
}

fn euclid_mullin_term(index: i64) -> i64 {
    let mut product = 1_i64;
    let mut term = 1_i64;
    for _ in 0..index {
        term = least_prime_factor(product + 1);
        product *= term;
    }
    term
}

#[no_mangle]
pub unsafe extern "C" fn euclid_mullin_sequence(
    input: *const i64,
    length: usize,
) -> i64 {
    if input.is_null() || !(1..=MAX_PARSEABLE_LENGTH).contains(&length) {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    if length != 1 || values[0] < 1 || values[0] > MAX_N {
        return -1;
    }
    euclid_mullin_term(values[0])
}
