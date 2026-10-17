const MAX_BIT_COUNT: usize = 128;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 130;
const MAX_OUTPUT_BYTES: usize = 1032;
const MAX_DICTIONARY_ENTRIES: usize = 130;
const MAX_KEY_LENGTH: usize = 129;
const MAX_CODE_WIDTH: usize = 8;

#[no_mangle]
pub unsafe extern "C" fn lempel_ziv(
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

    let mut keys = [0_u8; MAX_DICTIONARY_ENTRIES * MAX_KEY_LENGTH];
    let mut key_lengths = [0_usize; MAX_DICTIONARY_ENTRIES];
    let mut codes = [0_u8; MAX_DICTIONARY_ENTRIES * MAX_CODE_WIDTH];
    let mut code_lengths = [0_usize; MAX_DICTIONARY_ENTRIES];
    keys[0] = 48;
    keys[MAX_KEY_LENGTH] = 49;
    key_lengths[0] = 1;
    key_lengths[1] = 1;
    codes[0] = 48;
    codes[MAX_CODE_WIDTH] = 49;
    code_lengths[0] = 1;
    code_lengths[1] = 1;
    let mut entry_count = 2;
    let mut next_index = 2;
    let mut current = [0_u8; MAX_KEY_LENGTH];
    let mut current_length = 0;
    let mut result = [0_u8; MAX_OUTPUT_BYTES];
    let mut result_length = 0;

    for input_index in 0..bit_count {
        current[current_length] = values[input_index + 1] as u8;
        current_length += 1;
        let mut found = entry_count;
        for entry in 0..entry_count {
            if key_lengths[entry] == current_length
                && keys[entry * MAX_KEY_LENGTH..entry * MAX_KEY_LENGTH + current_length]
                    == current[..current_length]
            {
                found = entry;
                break;
            }
        }
        if found == entry_count {
            continue;
        }

        let last_code_length = code_lengths[found];
        let mut last_code = [0_u8; MAX_CODE_WIDTH];
        for component in 0..last_code_length {
            last_code[component] = codes[found * MAX_CODE_WIDTH + component];
            result[result_length] = last_code[component];
            result_length += 1;
        }
        for entry in found..entry_count - 1 {
            for component in 0..MAX_KEY_LENGTH {
                keys[entry * MAX_KEY_LENGTH + component] = keys[(entry + 1) * MAX_KEY_LENGTH + component];
            }
            for component in 0..MAX_CODE_WIDTH {
                codes[entry * MAX_CODE_WIDTH + component] = codes[(entry + 1) * MAX_CODE_WIDTH + component];
            }
            key_lengths[entry] = key_lengths[entry + 1];
            code_lengths[entry] = code_lengths[entry + 1];
        }
        entry_count -= 1;

        for component in 0..current_length {
            keys[entry_count * MAX_KEY_LENGTH + component] = current[component];
        }
        keys[entry_count * MAX_KEY_LENGTH + current_length] = 48;
        key_lengths[entry_count] = current_length + 1;
        for component in 0..last_code_length {
            codes[entry_count * MAX_CODE_WIDTH + component] = last_code[component];
        }
        code_lengths[entry_count] = last_code_length;
        entry_count += 1;

        if (next_index & (next_index - 1)) == 0 {
            for entry in 0..entry_count {
                let code_length = code_lengths[entry];
                for component in (1..=code_length).rev() {
                    codes[entry * MAX_CODE_WIDTH + component] = codes[entry * MAX_CODE_WIDTH + component - 1];
                }
                codes[entry * MAX_CODE_WIDTH] = 48;
                code_lengths[entry] = code_length + 1;
            }
        }
        for component in 0..current_length {
            keys[entry_count * MAX_KEY_LENGTH + component] = current[component];
        }
        keys[entry_count * MAX_KEY_LENGTH + current_length] = 49;
        key_lengths[entry_count] = current_length + 1;
        let mut code_width = 1;
        let mut temp = next_index;
        while temp > 1 {
            temp >>= 1;
            code_width += 1;
        }
        code_lengths[entry_count] = code_width;
        for component in 0..code_width {
            codes[entry_count * MAX_CODE_WIDTH + component] =
                b'0' + ((next_index >> (code_width - component - 1)) & 1) as u8;
        }
        entry_count += 1;
        next_index += 1;
        current_length = 0;
    }

    if current_length > 0 {
        let max_key_length = (0..entry_count).map(|entry| key_lengths[entry]).max().unwrap_or(0);
        let mut found = entry_count;
        while found == entry_count {
            for entry in 0..entry_count {
                if key_lengths[entry] == current_length
                    && keys[entry * MAX_KEY_LENGTH..entry * MAX_KEY_LENGTH + current_length]
                        == current[..current_length]
                {
                    found = entry;
                    break;
                }
            }
            if found == entry_count {
                if current_length >= max_key_length {
                    break;
                }
                current[current_length] = 48;
                current_length += 1;
            }
        }
        if found == entry_count {
            return -1;
        }
        for component in 0..code_lengths[found] {
            result[result_length] = codes[found * MAX_CODE_WIDTH + component];
            result_length += 1;
        }
    }

    if output.is_null() || output_capacity < result_length {
        return -2;
    }
    for index in 0..result_length {
        unsafe { *output.add(index) = result[index]; }
    }
    result_length as i64
}
