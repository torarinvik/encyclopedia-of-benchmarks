#[no_mangle]
pub extern "C" fn finding_number_of_digits_in_a_number(value: i64) -> i64 {
    if value < 0 {
        return -1;
    }
    let mut remaining = value as u64;
    let mut count = 0i64;
    while remaining != 0 {
        remaining /= 10;
        count += 1;
    }
    count
}
