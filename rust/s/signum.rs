/// Sign of a signed 64-bit integer.
#[no_mangle]
pub extern "C" fn signum(value: i64) -> i64 {
    (value > 0) as i64 - (value < 0) as i64
}
