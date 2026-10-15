#[no_mangle]
pub unsafe extern "C" fn snake_case_to_camel_pascal_case(
    raw: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if raw.is_null() || length < 2 || length > 257 {
        return -1;
    }
    let input = std::slice::from_raw_parts(raw, length);
    if input[0] != 0 && input[0] != 1 {
        return -1;
    }

    let input_length = length - 1;
    let mut output_length = 0usize;
    for index in 0..input_length {
        let value = input[index + 1];
        if value == 95 {
            if index == 0 || index + 1 == input_length || input[index] == 95 {
                return -1;
            }
        } else if !((97..=122).contains(&value) || (48..=57).contains(&value)) {
            return -1;
        } else {
            output_length += 1;
        }
    }
    if capacity < output_length || output.is_null() {
        return -2;
    }

    let result = std::slice::from_raw_parts_mut(output, output_length);
    let mut position = 0usize;
    let mut capitalize = input[0] == 1;
    for index in 0..input_length {
        let mut value = input[index + 1];
        if value == 95 {
            capitalize = true;
            continue;
        }
        if capitalize && (97..=122).contains(&value) {
            value -= 32;
        }
        result[position] = value as u8;
        position += 1;
        capitalize = false;
    }
    output_length as i64
}
