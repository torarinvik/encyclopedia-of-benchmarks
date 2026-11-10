/// Return the exact zero-based Catalan number through the signed 64-bit range.
#[no_mangle]
pub extern "C" fn catalan_number(n: i64) -> i64 {
    if !(0..=35).contains(&n) {
        return -1;
    }
    let mut value = 1i64;
    for index in 1..=n {
        let mut numerator = 4 * index - 2;
        let mut denominator = index + 1;
        let common = (if denominator % 3 == 0 { 3 } else { 1 }) * (if denominator % 2 == 0 { 2 } else { 1 });
        numerator /= common;
        denominator /= common;
        value = (value / denominator) * numerator;
    }
    value
}
