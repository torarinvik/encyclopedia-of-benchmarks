fn is_stripped_punctuation(value: u8) -> bool {
    matches!(value, b'.' | b',' | b'!' | b'?' | b'(' | b')' | b'[' | b']' | b'{' | b'}')
}

unsafe fn put_u32(output: *mut u8, offset: usize, value: u32) {
    for index in 0..4 {
        *output.add(offset + index) = (value >> (8 * index)) as u8;
    }
}

#[no_mangle]
pub unsafe extern "C" fn largest_smallest_words(
    values: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if values.is_null() || length < 1 || length > 515 { return -1; }
    let text_length_value = *values;
    if !(1..=512).contains(&text_length_value) || length != 1 + text_length_value as usize {
        return -1;
    }
    let text_length = text_length_value as usize;
    let mut text = [0u8; 512];
    for index in 0..text_length {
        let value = *values.add(index + 1);
        if !(32..=126).contains(&value) { return -1; }
        text[index] = value as u8;
    }
    let mut small_start = 0usize;
    let mut large_start = 0usize;
    let mut small_length = 513usize;
    let mut large_length = 0usize;
    let mut word_count = 0usize;
    let mut pos = 0usize;
    while pos < text_length {
        while pos < text_length && text[pos] == b' ' { pos += 1; }
        if pos == text_length { break; }
        let token_start = pos;
        while pos < text_length && text[pos] != b' ' { pos += 1; }
        let mut first = token_start;
        let mut last = pos;
        while first < last && is_stripped_punctuation(text[first]) { first += 1; }
        while last > first && is_stripped_punctuation(text[last - 1]) { last -= 1; }
        let word_length = last - first;
        if word_length < small_length { small_start = first; small_length = word_length; }
        if word_length > large_length { large_start = first; large_length = word_length; }
        word_count += 1;
    }
    if word_count == 0 { return -1; }
    let output_length = 8 + small_length + large_length;
    if output_capacity < output_length || output.is_null() { return -2; }
    put_u32(output, 0, small_length as u32);
    for index in 0..small_length { *output.add(4 + index) = text[small_start + index]; }
    let large_header = 4 + small_length;
    put_u32(output, large_header, large_length as u32);
    for index in 0..large_length { *output.add(large_header + 4 + index) = text[large_start + index]; }
    output_length as i64
}
