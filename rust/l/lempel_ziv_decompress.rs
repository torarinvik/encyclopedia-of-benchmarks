const MAX_BIT_COUNT: usize = 128;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 130;
const MAX_OUTPUT_BYTES: usize = 8256;
const MAX_DICTIONARY_ENTRIES: usize = 130;
const MAX_PHRASE_LENGTH: usize = 129;

#[no_mangle]
pub unsafe extern "C" fn lempel_ziv_decompress(
    input: *const i64,
    input_length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 1 || input_length > MAX_PARSEABLE_INPUT_LENGTH {
        return -1;
    }
    let values = unsafe { std::slice::from_raw_parts(input, input_length) };
    if values[0] < 0 || values[0] > MAX_BIT_COUNT as i64 {
        return -1;
    }
    let bit_count = values[0] as usize;
    if input_length != 1 + bit_count || values[1..].iter().any(|&bit| bit != 48 && bit != 49) {
        return -1;
    }

    let mut codes = [0_usize; MAX_DICTIONARY_ENTRIES];
    let mut phrase_lengths = [0_usize; MAX_DICTIONARY_ENTRIES];
    let mut phrases = [0_u8; MAX_DICTIONARY_ENTRIES * MAX_PHRASE_LENGTH];
    codes[0] = 0;
    codes[1] = 1;
    phrase_lengths[0] = 1;
    phrase_lengths[1] = 1;
    phrases[0] = 48;
    phrases[MAX_PHRASE_LENGTH] = 49;
    let mut entry_count = 2;
    let mut code_width = 1;
    let mut next_index = 2;
    let mut result = [0_u8; MAX_OUTPUT_BYTES];
    let mut result_length = 0;
    let mut cursor = 0;

    while cursor + code_width <= bit_count {
        let code_width_used = code_width;
        let mut code = 0;
        for bit_offset in 0..code_width_used {
            code = code * 2 + (values[cursor + bit_offset + 1] - 48) as usize;
        }
        let Some(found) = (0..entry_count).find(|&index| codes[index] == code) else {
            break;
        };

        let last_length = phrase_lengths[found];
        let mut last_phrase = [0_u8; MAX_PHRASE_LENGTH];
        for index in 0..last_length {
            let value = phrases[found * MAX_PHRASE_LENGTH + index];
            last_phrase[index] = value;
            result[result_length] = value;
            result_length += 1;
        }
        phrases[found * MAX_PHRASE_LENGTH + last_length] = 48;
        phrase_lengths[found] = last_length + 1;

        if (next_index & (next_index - 1)) == 0 {
            code_width += 1;
        }
        codes[entry_count] = next_index;
        phrase_lengths[entry_count] = last_length + 1;
        for index in 0..last_length {
            phrases[entry_count * MAX_PHRASE_LENGTH + index] = last_phrase[index];
        }
        phrases[entry_count * MAX_PHRASE_LENGTH + last_length] = 49;
        entry_count += 1;
        next_index += 1;
        cursor += code_width_used;
    }

    if output.is_null() || output_capacity < result_length {
        return -2;
    }
    for index in 0..result_length {
        unsafe { *output.add(index) = result[index]; }
    }
    result_length as i64
}
