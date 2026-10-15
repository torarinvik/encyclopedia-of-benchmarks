#[no_mangle]
pub unsafe extern "C" fn camel_case_to_snake_case(
    raw: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if length == 0 || length > 256 || raw.is_null() {
        return -1;
    }
    let input = std::slice::from_raw_parts(raw, length);
    let mut output_length = 0usize;
    for (index, value) in input.iter().enumerate() {
        if (65..=90).contains(value) {
            if index > 0 {
                output_length += 1;
            }
        } else if !(97..=122).contains(value) {
            return -1;
        }
        output_length += 1;
    }
    if capacity < output_length || output.is_null() {
        return -2;
    }

    let result = std::slice::from_raw_parts_mut(output, output_length);
    let mut position = 0;
    for (index, value) in input.iter().enumerate() {
        if (65..=90).contains(value) {
            if index > 0 {
                result[position] = b'_';
                position += 1;
            }
            result[position] = (*value + 32) as u8;
        } else {
            result[position] = *value as u8;
        }
        position += 1;
    }
    output_length as i64
}
