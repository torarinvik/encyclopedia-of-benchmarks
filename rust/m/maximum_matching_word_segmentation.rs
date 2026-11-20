const MAX_TEXT: usize = 64;
const MAX_WORDS: usize = 16;
const MAX_WORD_LENGTH: usize = 8;
const MAX_PARSEABLE_LENGTH: usize = 211;

#[no_mangle]
pub unsafe extern "C" fn maximum_matching_word_segmentation(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_PARSEABLE_LENGTH {
        return -1;
    }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let text_length_value = values[0];
    let word_count_value = values[1];
    if !(0..=MAX_TEXT as i64).contains(&text_length_value)
        || !(0..=MAX_WORDS as i64).contains(&word_count_value)
    {
        return -1;
    }
    let text_length = text_length_value as usize;
    let word_count = word_count_value as usize;
    if length < 2 + text_length || values[2..2 + text_length].iter().any(|&c| !(97..=122).contains(&c)) {
        return -1;
    }

    let mut word_offsets = [0_usize; MAX_WORDS];
    let mut word_lengths = [0_usize; MAX_WORDS];
    let mut cursor = 2 + text_length;
    for word in 0..word_count {
        if cursor >= length {
            return -1;
        }
        let word_length_value = values[cursor];
        cursor += 1;
        if !(1..=MAX_WORD_LENGTH as i64).contains(&word_length_value) {
            return -1;
        }
        let word_length = word_length_value as usize;
        if word_length > length - cursor
            || values[cursor..cursor + word_length].iter().any(|&c| !(97..=122).contains(&c))
        {
            return -1;
        }
        word_offsets[word] = cursor;
        word_lengths[word] = word_length;
        cursor += word_length;
    }
    if cursor != length {
        return -1;
    }

    let mut token_ids = [0_u8; MAX_TEXT];
    let mut token_count = 0;
    let mut position = 0;
    while position < text_length {
        let mut best_length = 0;
        let mut best_id = 0_u8;
        for word in 0..word_count {
            let candidate_length = word_lengths[word];
            if candidate_length <= best_length || candidate_length > text_length - position {
                continue;
            }
            let mut offset = 0;
            while offset < candidate_length
                && values[word_offsets[word] + offset] == values[2 + position + offset]
            {
                offset += 1;
            }
            if offset == candidate_length {
                best_length = candidate_length;
                best_id = (word + 1) as u8;
            }
        }
        token_ids[token_count] = best_id;
        token_count += 1;
        position += if best_length == 0 { 1 } else { best_length };
    }

    let output_length = token_count + 1;
    if output.is_null() || capacity < output_length {
        return -2;
    }
    let output = unsafe { std::slice::from_raw_parts_mut(output, output_length) };
    output[0] = token_count as u8;
    output[1..].copy_from_slice(&token_ids[..token_count]);
    output_length as i64
}
