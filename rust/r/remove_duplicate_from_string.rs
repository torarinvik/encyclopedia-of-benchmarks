const MAX_TEXT_LENGTH: usize = 512;
const MAX_INPUT_LENGTH: usize = MAX_TEXT_LENGTH + 2;

#[no_mangle]
pub unsafe extern "C" fn remove_duplicate_from_string(
    input: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT_LENGTH {
        return -1;
    }
    let raw = unsafe { std::slice::from_raw_parts(input, length) };
    if raw[0] < 0 || raw[0] > MAX_TEXT_LENGTH as i64 {
        return -1;
    }
    let text_length = raw[0] as usize;
    if length != 1 + text_length {
        return -1;
    }
    let mut result = [0u8; MAX_TEXT_LENGTH];
    let mut seen = [false; 128];
    let mut result_length = 0usize;
    for index in 0..text_length {
        let value = raw[index + 1];
        if !(0..=127).contains(&value) {
            return -1;
        }
        let byte = value as usize;
        if !seen[byte] {
            seen[byte] = true;
            result[result_length] = value as u8;
            result_length += 1;
        }
    }
    if output_capacity < result_length || (result_length != 0 && output.is_null()) {
        return -2;
    }
    for index in 0..result_length {
        unsafe { *output.add(index) = result[index]; }
    }
    result_length as i64
}
