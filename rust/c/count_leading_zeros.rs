#[no_mangle]
pub extern "C" fn count_leading_zeros(value: i64) -> i64 {
    if value < i32::MIN as i64 || value > i32::MAX as i64 {
        return -1;
    }
    if value == 0 {
        return 32;
    }
    let mut mask = 1i64 << 31;
    let mut count = 0i64;
    while (mask & value) == 0 {
        count += 1;
        mask >>= 1;
    }
    count
}
