const MAX_N: i64 = 1_000_000_000_000;
const MAX_PARSEABLE_LENGTH: usize = 2;

fn derivative_from_factors(value: i64) -> i64 {
    if value < 2 {
        return 0;
    }
    let original = value;
    let mut remaining = value;
    let mut derivative = 0i64;
    let mut factor = 2i64;
    while factor <= remaining / factor {
        if remaining % factor == 0 {
            let mut exponent = 0i64;
            while remaining % factor == 0 {
                remaining /= factor;
                exponent += 1;
            }
            derivative += (original / factor) * exponent;
        }
        factor = if factor == 2 { 3 } else { factor + 2 };
    }
    if remaining > 1 {
        derivative += original / remaining;
    }
    derivative
}

#[no_mangle]
pub unsafe extern "C" fn arithmetic_derivative(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(1..=MAX_PARSEABLE_LENGTH).contains(&length) {
        return -1;
    }
    if length != 1 {
        return -1;
    }
    let n = *input;
    if !(0..=MAX_N).contains(&n) {
        return -1;
    }
    derivative_from_factors(n)
}
