/// Return 1 when n is divisible by seven or ends in decimal digit seven.
#[no_mangle]
pub extern "C" fn buzz_number(n: i64) -> i64 {
    if n % 7 == 0 || (n >= 0 && n % 10 == 7) { 1 } else { 0 }
}
