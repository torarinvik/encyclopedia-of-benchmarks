fn lower_ascii(value: i64) -> i64 {
    if (65..=90).contains(&value) { value + 32 } else { value }
}

#[no_mangle]
pub extern "C" fn percentage_of_letters(values: *const i64, length: usize) -> i64 {
    if length < 2 || length > 4097 || values.is_null() { return -1; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    let target = lower_ascii(values[0]);
    if !(97..=122).contains(&target) { return -1; }
    let text = &values[1..];
    let mut matches = 0usize;
    for &value in text {
        if !(0..=127).contains(&value) { return -1; }
        if lower_ascii(value) == target { matches += 1; }
    }
    ((100 * matches) / text.len()) as i64
}
