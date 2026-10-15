#[no_mangle]
pub unsafe extern "C" fn title_case_conversion(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 1 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(0..=256).contains(&values[0]) || length != values[0] as usize + 1 { return -1; }
    let n = values[0] as usize;
    for i in 0..n {
        let value = values[i + 1];
        if (65..=90).contains(&value) || (97..=122).contains(&value) { continue; }
        if value == 32 && i > 0 && i + 1 < n && values[i] != 32 { continue; }
        return -1;
    }
    if output.is_null() || capacity < n + 1 { return -2; }
    let result = std::slice::from_raw_parts_mut(output, capacity);
    let mut at_word_start = true;
    for i in 0..n {
        let mut value = values[i + 1];
        if value == 32 {
            result[i] = 32;
            at_word_start = true;
        } else if at_word_start {
            if (97..=122).contains(&value) { value -= 32; }
            result[i] = value as u8;
            at_word_start = false;
        } else {
            if (65..=90).contains(&value) { value += 32; }
            result[i] = value as u8;
        }
    }
    result[n] = 0;
    n as i64
}
