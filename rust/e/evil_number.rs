/// Return 1 when a nonnegative integer has an even popcount.
#[no_mangle]
pub extern "C" fn evil_number(value: i64) -> i64 {
    if value < 0 {
        return -1;
    }
    let mut remaining = value as u64;
    let mut count = 0;
    while remaining > 0 {
        count += (remaining & 1) as i64;
        remaining >>= 1;
    }
    if count % 2 == 0 { 1 } else { 0 }
}
