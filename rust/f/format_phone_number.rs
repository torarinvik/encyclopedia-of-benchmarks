#[no_mangle]
pub unsafe extern "C" fn format_phone_number(
    values: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if values.is_null() || length != 10 {
        return -1;
    }
    let values = std::slice::from_raw_parts(values, length);
    if values.iter().any(|&digit| !(48..=57).contains(&digit)) {
        return -1;
    }
    if output.is_null() || output_capacity < 14 {
        return -2;
    }
    let output = std::slice::from_raw_parts_mut(output, output_capacity);
    output[0] = b'(';
    for index in 0..3 {
        output[index + 1] = values[index] as u8;
    }
    output[4] = b')';
    output[5] = b' ';
    for index in 0..3 {
        output[index + 6] = values[index + 3] as u8;
    }
    output[9] = b'-';
    for index in 0..4 {
        output[index + 10] = values[index + 6] as u8;
    }
    14
}
