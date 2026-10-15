#[no_mangle]
pub extern "C" fn parity_check(value: i64) -> i64 {
    if value < i32::MIN as i64 || value > i32::MAX as i64 { return -1; }
    let mut number = value as i32;
    let mut parity = 0i32;
    while number > 0 {
        parity ^= number & 1;
        number >>= 1;
    }
    if parity == 0 { 1 } else { 0 }
}
