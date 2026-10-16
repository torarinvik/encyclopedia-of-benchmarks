/// Bounded port of TheAlgorithms/Python Project Euler 33.
fn gcd_i64(mut left: i64, mut right: i64) -> i64 {
    while right != 0 {
        let remainder = left % right;
        left = right;
        right = remainder;
    }
    left
}

#[no_mangle]
pub extern "C" fn problem33(digit_len: i64) -> i64 {
    if !(0..=5).contains(&digit_len) {
        return -1;
    }
    let mut upper = 1i64;
    for _ in 0..digit_len {
        upper *= 10;
    }
    let mut result = 1.0f64;
    let mut denominator = 11i64;
    for numerator in 11..upper {
        while denominator <= 99 {
            if numerator != denominator
                && numerator % 10 == denominator / 10
                && denominator % 10 != 0
                && (numerator / 10) as f64 / (denominator % 10) as f64
                    == numerator as f64 / denominator as f64
            {
                let divisor = gcd_i64(numerator, denominator);
                result *= (denominator / divisor) as f64 / (numerator / divisor) as f64;
            }
            denominator += 1;
        }
        denominator = 10;
    }
    result as i64
}
