/// Return 1 for an odd signed 64-bit integer and 0 for an even one.
#[no_mangle]
pub extern "C" fn is_odd(value: i64) -> i64 {
    (value % 2 != 0) as i64
}
