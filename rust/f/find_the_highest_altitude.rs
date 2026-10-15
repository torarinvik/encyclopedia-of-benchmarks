#[no_mangle]
pub extern "C" fn find_the_highest_altitude(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length == 0 { return -1; }
    let packed = unsafe { std::slice::from_raw_parts(input, length) };
    if !(0..=1024).contains(&packed[0]) || length != packed[0] as usize + 1 { return -1; }
    let mut altitude = 0i64;
    let mut maximum = 0i64;
    for &gain in &packed[1..] {
        if gain < i32::MIN as i64 || gain > i32::MAX as i64 { return -1; }
        altitude += gain;
        if altitude > maximum { maximum = altitude; }
    }
    maximum
}
