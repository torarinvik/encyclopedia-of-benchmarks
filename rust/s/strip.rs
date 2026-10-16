const MAX_TEXT_LENGTH: usize = 256;
const MAX_CHARACTER_LENGTH: usize = 128;

unsafe fn contains_character(value: i64, input: &[i64], set_start: usize,
                             set_length: i64) -> bool {
    if set_length == -1 { return value == 9 || value == 10 || value == 13 || value == 32; }
    input[set_start..set_start + set_length as usize].contains(&value)
}

#[no_mangle]
pub unsafe extern "C" fn strip(input: *const i64, length: usize,
                                  output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > 386 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    if values[0] < 0 || values[0] as usize > MAX_TEXT_LENGTH { return -1; }
    let text_length = values[0] as usize;
    let set_index = 1 + text_length;
    if set_index >= length { return -1; }
    let set_length = values[set_index];
    let expected_length = if set_length == -1 {
        set_index + 1
    } else {
        if set_length < 0 || set_length as usize > MAX_CHARACTER_LENGTH { return -1; }
        set_index + 1 + set_length as usize
    };
    if length != expected_length { return -1; }
    if values[1..set_index].iter().any(|&value| !(0..=127).contains(&value)) { return -1; }
    if set_length >= 0 && values[set_index + 1..].iter().any(|&value| !(0..=127).contains(&value)) {
        return -1;
    }

    let mut start = 0usize;
    let mut end = text_length;
    while start < end && unsafe { contains_character(values[1 + start], values, set_index + 1, set_length) } {
        start += 1;
    }
    while end > start && unsafe { contains_character(values[end], values, set_index + 1, set_length) } {
        end -= 1;
    }
    let output_length = end - start;
    if output_length > output_capacity || (output_length > 0 && output.is_null()) { return -2; }
    if output_length > 0 {
        for index in 0..output_length {
            unsafe { *output.add(index) = values[1 + start + index] as u8; }
        }
    }
    output_length as i64
}
