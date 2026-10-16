fn compare_words(values: &[i64], start_a: usize, length_a: usize,
                 start_b: usize, length_b: usize) -> std::cmp::Ordering {
    let common = length_a.min(length_b);
    for index in 0..common {
        match values[1 + start_a + index].cmp(&values[1 + start_b + index]) {
            std::cmp::Ordering::Equal => {}
            order => return order,
        }
    }
    length_a.cmp(&length_b)
}

#[no_mangle]
pub unsafe extern "C" fn remove_duplicate(values: *const i64, length: usize,
                                              output: *mut u8, output_capacity: usize) -> i64 {
    if values.is_null() || length < 1 { return -1; }
    let input = std::slice::from_raw_parts(values, length);
    if input[0] < 0 || input[0] > 1024 || length != 1 + input[0] as usize { return -1; }
    let text_length = input[0] as usize;
    if input[1..].iter().any(|byte| *byte != 32 && !(*byte >= 97 && *byte <= 122)) { return -1; }
    let mut starts = [0_usize; 512];
    let mut word_lengths = [0_usize; 512];
    let mut word_count = 0;
    let mut cursor = 0;
    while cursor < text_length {
        if input[cursor + 1] == 32 { cursor += 1; continue; }
        starts[word_count] = cursor;
        while cursor < text_length && input[cursor + 1] != 32 { cursor += 1; }
        word_lengths[word_count] = cursor - starts[word_count];
        word_count += 1;
    }
    for index in 1..word_count {
        let key_start = starts[index];
        let key_length = word_lengths[index];
        let mut position = index;
        while position > 0 && compare_words(input, starts[position - 1], word_lengths[position - 1],
                                            key_start, key_length).is_gt() {
            starts[position] = starts[position - 1];
            word_lengths[position] = word_lengths[position - 1];
            position -= 1;
        }
        starts[position] = key_start;
        word_lengths[position] = key_length;
    }
    let mut output_length = 0;
    let mut unique_count = 0;
    for index in 0..word_count {
        if index > 0 && compare_words(input, starts[index - 1], word_lengths[index - 1],
                                      starts[index], word_lengths[index]).is_eq() { continue; }
        if unique_count > 0 { output_length += 1; }
        output_length += word_lengths[index];
        unique_count += 1;
    }
    if output_length > output_capacity || (output_length > 0 && output.is_null()) { return -2; }
    let mut written = 0;
    let mut emitted = 0;
    for index in 0..word_count {
        if index > 0 && compare_words(input, starts[index - 1], word_lengths[index - 1],
                                      starts[index], word_lengths[index]).is_eq() { continue; }
        if emitted > 0 { *output.add(written) = b' '; written += 1; }
        for byte in 0..word_lengths[index] {
            *output.add(written) = input[1 + starts[index] + byte] as u8;
            written += 1;
        }
        emitted += 1;
    }
    output_length as i64
}
