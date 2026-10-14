/// Return the exact zero-based Catalan number through the signed 64-bit range.
fn gcd_i64(mut left: i64, mut right: i64) -> i64 {
    while right != 0 {
        let remainder = left % right;
        left = right;
        right = remainder;
    }
    left
}

#[no_mangle]
pub extern "C" fn catalan_number(n: i64) -> i64 {
    if !(0..=35).contains(&n) {
        return -1;
    }
    let mut value = 1i64;
    for index in 1..=n {
        let mut numerator = 4 * index - 2;
        let mut denominator = index + 1;
        let common = gcd_i64(numerator, denominator);
        numerator /= common;
        denominator /= common;
        value = (value / denominator) * numerator;
    }
    value
}
