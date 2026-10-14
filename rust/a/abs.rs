/// Return the signed 64-bit magnitude, or -1 when it cannot be represented.
#[no_mangle]
pub extern "C" fn abs_i64(input: i64) -> i64 {
    if input == i64::MIN {
        return -1;
    }
    if input < 0 { -input } else { input }
}
