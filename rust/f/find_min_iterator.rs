#[no_mangle]
pub extern "C" fn find_min_iterator(input: *const i64, length: usize) -> i64 {
    if length < 1 || length > 129 || input.is_null() { return -1; }
    let input = unsafe { std::slice::from_raw_parts(input, length) };
    if input[0] < 0 || input[0] > 128 || length != input[0] as usize + 1 { return -1; }
    if input[0] == 0 { return -1; }
    let mut minimum = i64::MAX;
    for &value in &input[1..] {
        if !(0..=2_147_483_647).contains(&value) { return -1; }
        if value < minimum { minimum = value; }
    }
    minimum
}
