/// Return 1 for an even signed 64-bit integer and 0 for an odd one.
#[no_mangle]
pub extern "C" fn check_even(value: i64) -> i64 {
    (value % 2 == 0) as i64
}
