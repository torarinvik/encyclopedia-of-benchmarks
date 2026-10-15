#[no_mangle]
pub extern "C" fn binary_length(value: i64) -> i64 {
    if value <= 0 || value > i32::MAX as i64 {
        return -1;
    }
    (value as f64).log2().floor() as i64 + 1
}
