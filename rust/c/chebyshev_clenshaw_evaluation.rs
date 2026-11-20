/// Clenshaw's backward recurrence for Chebyshev coefficients over a prime field.
const MODULUS: i64 = 998_244_353;
const MAX_DEGREE: usize = 16;
const MAX_PARSEABLE_LENGTH: usize = 21;

fn reduce_field(value: i64) -> i64 {
    value.rem_euclid(MODULUS)
}

#[no_mangle]
pub unsafe extern "C" fn chebyshev_clenshaw_evaluation(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(3..=MAX_PARSEABLE_LENGTH).contains(&length) {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    let degree_value = values[0];
    if !(0..=MAX_DEGREE as i64).contains(&degree_value) {
        return -1;
    }
    let degree = degree_value as usize;
    if length != degree + 3 {
        return -1;
    }
    let x = values[1];
    if !(0..MODULUS).contains(&x) || values[2..].iter().any(|&coefficient| !(0..MODULUS).contains(&coefficient)) {
        return -1;
    }

    let twice_x = (2 * x) % MODULUS;
    let mut next_one = 0i64;
    let mut next_two = 0i64;
    for k in (1..=degree).rev() {
        let current = reduce_field(values[2 + k] + twice_x * next_one - next_two);
        next_two = next_one;
        next_one = current;
    }
    reduce_field(values[2] + x * next_one - next_two)
}
