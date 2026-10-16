const MAX_WORDS: usize = 8;
const MAX_PATH_WORDS: usize = MAX_WORDS + 1;
const MAX_INPUT_LENGTH: usize = 4 + MAX_WORDS;
const MAX_OUTPUT_FIELDS: usize = MAX_PATH_WORDS + MAX_WORDS + 2;

fn power_of_26(exponent: usize) -> i64 {
    let mut result = 1i64;
    for _ in 0..exponent {
        result *= 26;
    }
    result
}

fn find_active_word(words: &[i64], active: &[bool; MAX_WORDS], candidate: i64) -> Option<usize> {
    for (index, &word) in words.iter().enumerate() {
        if active[index] && word == candidate {
            return Some(index);
        }
    }
    None
}

fn backtrack(
    current: i64,
    target: i64,
    width: usize,
    words: &[i64],
    active: &mut [bool; MAX_WORDS],
    path: &mut [i64; MAX_PATH_WORDS],
    path_length: &mut usize,
) -> bool {
    if current == target {
        return true;
    }
    for position in 0..width {
        let factor = power_of_26(width - position - 1);
        let digit = (current / factor) % 26;
        for replacement in 0..26i64 {
            let candidate = current + (replacement - digit) * factor;
            let Some(index) = find_active_word(words, active, candidate) else {
                continue;
            };
            active[index] = false;
            path[*path_length] = candidate;
            *path_length += 1;
            if backtrack(candidate, target, width, words, active, path, path_length) {
                return true;
            }
            *path_length -= 1;
            active[index] = true;
        }
    }
    false
}

fn write_i64_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn word_ladder_dfs(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 4 || length > MAX_INPUT_LENGTH {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    let width_value = values[0];
    let begin = values[1];
    let end = values[2];
    let count_value = values[3];
    if !(1..=5).contains(&width_value)
        || !(0..=MAX_WORDS as i64).contains(&count_value)
        || length != 4 + count_value as usize
    {
        return -1;
    }
    let width = width_value as usize;
    let words = &values[4..];
    let limit = power_of_26(width);
    if begin < 0 || begin >= limit || end < 0 || end >= limit {
        return -1;
    }
    for (index, &word) in words.iter().enumerate() {
        if word < 0 || word >= limit || (index > 0 && words[index - 1] >= word) {
            return -1;
        }
    }

    let mut active = [false; MAX_WORDS];
    for index in 0..words.len() {
        active[index] = true;
    }
    let mut path = [0i64; MAX_PATH_WORDS];
    path[0] = begin;
    let mut path_length = 1usize;
    if find_active_word(words, &active, end).is_some() {
        if !backtrack(
            begin,
            end,
            width,
            words,
            &mut active,
            &mut path,
            &mut path_length,
        ) {
            path_length = 0;
        }
    } else {
        path_length = 0;
    }

    let mut fields = [0i64; MAX_OUTPUT_FIELDS];
    let mut field_count = 0usize;
    fields[field_count] = path_length as i64;
    field_count += 1;
    for &word in &path[..path_length] {
        fields[field_count] = word;
        field_count += 1;
    }
    let remaining_count = words
        .iter()
        .enumerate()
        .filter(|(index, _)| active[*index])
        .count();
    fields[field_count] = remaining_count as i64;
    field_count += 1;
    for (index, &word) in words.iter().enumerate() {
        if active[index] {
            fields[field_count] = word;
            field_count += 1;
        }
    }

    let required = field_count * 8;
    if output.is_null() || capacity < required {
        return -2;
    }
    let output_bytes = std::slice::from_raw_parts_mut(output, required);
    for (index, &value) in fields[..field_count].iter().enumerate() {
        write_i64_le(output_bytes, index * 8, value);
    }
    required as i64
}
