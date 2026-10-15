/// Match n against the signed sum of the cubes of its decimal digits.
#[no_mangle]
pub extern "C" fn armstrong_digit_cubes(n: i64) -> i64 {
    if n < i32::MIN as i64 || n > i32::MAX as i64 { return -1; }
    let original = n;
    let mut magnitude = n.abs();
    let mut sum = 0i64;
    while magnitude > 0 {
        let digit = magnitude % 10;
        sum += digit * digit * digit;
        magnitude /= 10;
    }
    if original < 0 { sum = -sum; }
    if sum == original { 1 } else { 0 }
}
