const MAX_EXPONENT: i64 = 31;
const INVALID_RESULT: i64 = i64::MIN;

fn integer_power(base: i64, exponent: i64) -> i64 {
    let mut result = 1i64;
    for _ in 0..exponent { result *= base; }
    result
}

fn binomial_coefficient(n: i64, k: i64) -> i64 {
    let mut coefficients = [0i64; 32];
    coefficients[0] = 1;
    for row in 1..=n {
        let mut column = row.min(k);
        while column > 0 {
            coefficients[column as usize] += coefficients[(column - 1) as usize];
            column -= 1;
        }
    }
    coefficients[k as usize]
}

/// Evaluate the bounded integer binomial expansion exactly.
#[no_mangle]
pub unsafe extern "C" fn binomial_expansion(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != 3 { return INVALID_RESULT; }
    let values = unsafe { core::slice::from_raw_parts(input, 3) };
    let (a, b, exponent) = (values[0], values[1], values[2]);
    if !(-2..=2).contains(&a) || !(-2..=2).contains(&b) || !(0..=MAX_EXPONENT).contains(&exponent) {
        return INVALID_RESULT;
    }
    let mut result = 0i64;
    for index in 0..=exponent {
        result += binomial_coefficient(exponent, index) *
            integer_power(a, exponent - index) * integer_power(b, index);
    }
    result
}
