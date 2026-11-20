const MAX_N: i64 = 22;
const MAX_PARSEABLE_LENGTH: usize = 2;

fn gcd(mut left: i64, mut right: i64) -> i64 {
    while right != 0 {
        let remainder = left % right;
        left = right;
        right = remainder;
    }
    left
}

fn reduced_harmonic_numerator(n: i64) -> i64 {
    let (mut numerator, mut denominator) = (0_i64, 1_i64);
    for k in 1..=n {
        let square = k * k;
        let shared = gcd(denominator, square);
        let scale = square / shared;
        numerator = numerator * scale + denominator / shared;
        denominator *= scale;
        let factor = gcd(numerator, denominator);
        numerator /= factor;
        denominator /= factor;
    }
    numerator
}

#[no_mangle]
pub unsafe extern "C" fn wolstenholme_numbers(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(1..=MAX_PARSEABLE_LENGTH).contains(&length) { return -1; }
    if length != 1 { return -1; }
    let n = unsafe { *input };
    if !(1..=MAX_N).contains(&n) { return -1; }
    reduced_harmonic_numerator(n)
}
