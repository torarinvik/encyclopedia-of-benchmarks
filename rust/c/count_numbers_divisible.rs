/// Count multiples of divisor in the inclusive positive integer interval [first, last].
#[no_mangle]
pub extern "C" fn count_numbers_divisible(first: f64, last: f64, divisor: f64) -> f64 {
    let a = first as i64;
    let b = last as i64;
    let m = divisor as i64;
    (b / m - (a - 1) / m) as f64
}
