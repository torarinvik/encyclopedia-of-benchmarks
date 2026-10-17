const MAX_PATTERN_LENGTH: usize = 8;
const MAX_TEXT_LENGTH: usize = 32;
const MAX_INPUT_LENGTH: usize = 43;

fn match_word_pattern_search(
    pattern: &[i64],
    text: &[i64],
    pattern_index: usize,
    text_index: usize,
    mapped_start: &mut [usize; 128],
    mapped_length: &mut [usize; 128],
) -> bool {
    if pattern_index == pattern.len() {
        return text_index == text.len();
    }
    if text_index == text.len() {
        return false;
    }

    let symbol = pattern[pattern_index] as usize;
    let known_length = mapped_length[symbol];
    if known_length != 0 {
        if known_length > text.len() - text_index {
            return false;
        }
        for offset in 0..known_length {
            if text[mapped_start[symbol] + offset] != text[text_index + offset] {
                return false;
            }
        }
        return match_word_pattern_search(
            pattern, text, pattern_index + 1, text_index + known_length,
            mapped_start, mapped_length,
        );
    }

    for end in text_index + 1..=text.len() {
        let candidate_length = end - text_index;
        let mut already_used = false;
        for &other_symbol_value in &pattern[..pattern_index] {
            let other = other_symbol_value as usize;
            if other == symbol {
                continue;
            }
            if mapped_length[other] != candidate_length {
                continue;
            }
            let equal = (0..candidate_length).all(|offset| {
                text[mapped_start[other] + offset] == text[text_index + offset]
            });
            if equal {
                already_used = true;
                break;
            }
        }
        if already_used {
            continue;
        }

        mapped_start[symbol] = text_index;
        mapped_length[symbol] = candidate_length;
        if match_word_pattern_search(
            pattern, text, pattern_index + 1, end, mapped_start, mapped_length,
        ) {
            return true;
        }
        mapped_length[symbol] = 0;
    }
    false
}

#[no_mangle]
pub extern "C" fn match_word_pattern(input: *const i64, input_length: usize) -> i64 {
    if input.is_null() || input_length < 2 || input_length > MAX_INPUT_LENGTH {
        return -1;
    }
    let input = unsafe { std::slice::from_raw_parts(input, input_length) };
    if !(0..=MAX_PATTERN_LENGTH as i64).contains(&input[0])
        || !(0..=MAX_TEXT_LENGTH as i64).contains(&input[1])
    {
        return -1;
    }
    let pattern_length = input[0] as usize;
    let text_length = input[1] as usize;
    if input_length != 2 + pattern_length + text_length {
        return -1;
    }
    let pattern = &input[2..2 + pattern_length];
    let text = &input[2 + pattern_length..];
    if pattern.iter().chain(text).any(|&value| !(0..=127).contains(&value)) {
        return -1;
    }

    let mut mapped_start = [0usize; 128];
    let mut mapped_length = [0usize; 128];
    i64::from(match_word_pattern_search(
        pattern, text, 0, 0, &mut mapped_start, &mut mapped_length,
    ))
}
