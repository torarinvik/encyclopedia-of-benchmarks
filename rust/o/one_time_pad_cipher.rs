const MAX_TEXT_LENGTH: usize = 1024;

#[no_mangle]
pub unsafe extern "C" fn one_time_pad_cipher(input: *const i64, length: usize,
                                               output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > 2 + 2 * MAX_TEXT_LENGTH { return -1; }
    let mode = *input;
    let count_value = *input.add(1);
    if (mode != 0 && mode != 1) || count_value < 0 || count_value > MAX_TEXT_LENGTH as i64 { return -1; }
    let count = count_value as usize;
    if length != 2 + 2 * count { return -1; }
    if output_capacity < count || (count > 0 && output.is_null()) { return -2; }
    for index in 0..count {
        let data = *input.add(2 + index);
        let key = *input.add(2 + count + index);
        if !(0..=255).contains(&data) || !(0..=255).contains(&key) { return -1; }
        *output.add(index) = (data ^ key) as u8;
    }
    count as i64
}
