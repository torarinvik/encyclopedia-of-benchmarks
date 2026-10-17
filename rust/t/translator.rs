const MAX_KEYS: usize = 4;
const MAX_KEY_LENGTH: usize = 4;
const MAX_TEXT_LENGTH: usize = 64;
const MAX_INPUT_LENGTH: usize = 107;
const MAX_OUTPUT_LENGTH: usize = 256;

#[no_mangle]
pub unsafe extern "C" fn translator(input: *const i64, length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(0..=MAX_KEYS as i64).contains(&values[0]) || !(0..=MAX_TEXT_LENGTH as i64).contains(&values[1]) { return -1; }
    let key_count = values[0] as usize;
    let text_length = values[1] as usize;
    let mut keys = [[0u8; MAX_KEY_LENGTH]; MAX_KEYS];
    let mut replacements = [[0u8; MAX_KEY_LENGTH]; MAX_KEYS];
    let mut key_lengths = [0usize; MAX_KEYS];
    let mut replacement_lengths = [0usize; MAX_KEYS];
    let mut cursor = 2usize;
    for key_index in 0..key_count {
        if cursor + 2 > length { return -1; }
        let key_length_value = values[cursor];
        let value_length_value = values[cursor + 1];
        cursor += 2;
        if !(1..=MAX_KEY_LENGTH as i64).contains(&key_length_value) || !(0..=MAX_KEY_LENGTH as i64).contains(&value_length_value) { return -1; }
        let key_length = key_length_value as usize;
        let value_length = value_length_value as usize;
        if cursor + key_length + value_length > length { return -1; }
        for index in 0..key_length {
            let byte = values[cursor + index];
            if !(32..=126).contains(&byte) { return -1; }
            keys[key_index][index] = byte as u8;
        }
        cursor += key_length;
        for index in 0..value_length {
            let byte = values[cursor + index];
            if !(32..=126).contains(&byte) { return -1; }
            replacements[key_index][index] = byte as u8;
        }
        cursor += value_length;
        key_lengths[key_index] = key_length;
        replacement_lengths[key_index] = value_length;
        for previous in 0..key_index {
            if key_lengths[previous] == key_length && keys[previous][..key_length] == keys[key_index][..key_length] { return -1; }
        }
    }
    if cursor + text_length != length { return -1; }
    let mut text = [0u8; MAX_TEXT_LENGTH];
    for index in 0..text_length {
        let byte = values[cursor + index];
        if !(32..=126).contains(&byte) { return -1; }
        text[index] = byte as u8;
    }

    let mut result = [0u8; MAX_OUTPUT_LENGTH];
    let mut result_length = 0usize;
    let mut start = 0usize;
    while start < text_length {
        let mut matched = false;
        let maximum_length = core::cmp::min(MAX_KEY_LENGTH, text_length - start);
        for candidate_length in 1..=maximum_length {
            for key_index in 0..key_count {
                if key_lengths[key_index] == candidate_length && text[start..start + candidate_length] == keys[key_index][..candidate_length] {
                    for index in 0..replacement_lengths[key_index] {
                        result[result_length + index] = replacements[key_index][index];
                    }
                    result_length += replacement_lengths[key_index];
                    start += candidate_length;
                    matched = true;
                    break;
                }
            }
            if matched { break; }
        }
        if !matched { break; }
    }
    if output.is_null() || capacity < result_length { return -2; }
    if result_length != 0 { std::ptr::copy_nonoverlapping(result.as_ptr(), output, result_length); }
    result_length as i64
}
