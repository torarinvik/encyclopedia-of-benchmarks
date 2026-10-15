/// Count Julia-regex words after ASCII lowercasing.
#[derive(Clone, Copy)]
struct WordEntry { start: usize, length: usize, count: usize }

fn lower_byte(input: &[i64], index: usize) -> u8 {
    let byte = input[index] as u8;
    if (b'A'..=b'Z').contains(&byte) { byte + (b'a' - b'A') } else { byte }
}
fn is_word_byte(byte: u8) -> bool {
    byte.is_ascii_lowercase() || byte.is_ascii_digit() || byte == b'_'
}
fn compare_word(input: &[i64], start: usize, length: usize, entry: WordEntry) -> std::cmp::Ordering {
    let shared = length.min(entry.length);
    for offset in 0..shared {
        match lower_byte(input, start + offset).cmp(&lower_byte(input, entry.start + offset)) {
            std::cmp::Ordering::Equal => {}, ordering => return ordering,
        }
    }
    length.cmp(&entry.length)
}
fn write_count(output: &mut [u8], mut position: usize, mut count: usize) -> usize {
    let mut digits = [0u8; 4]; let mut digit_count = 0;
    loop { digits[digit_count] = b'0' + (count % 10) as u8; digit_count += 1; count /= 10; if count == 0 { break; } }
    output[position] = b'='; position += 1;
    while digit_count > 0 { digit_count -= 1; output[position] = digits[digit_count]; position += 1; }
    output[position] = b'\n'; position + 1
}

#[no_mangle]
pub unsafe extern "C" fn word_count_julia(input: *const i64, length: usize,
                                            output: *mut u8, output_capacity: usize) -> i64 {
    if length > 1000 || (length != 0 && input.is_null()) { return -1; }
    let input = if length == 0 { &[][..] } else { std::slice::from_raw_parts(input, length) };
    if input.iter().any(|&value| !(0..=127).contains(&value)) { return -1; }
    let mut entries = [WordEntry { start: 0, length: 0, count: 0 }; 1000];
    let mut unique_count = 0usize; let mut index = 0usize;
    while index < length {
        if !is_word_byte(lower_byte(input, index)) { index += 1; continue; }
        let start = index;
        while index < length && is_word_byte(lower_byte(input, index)) { index += 1; }
        let mut token_length = index - start;
        if index + 1 < length && input[index] == b'\'' as i64 && is_word_byte(lower_byte(input, index + 1)) {
            token_length += 2; index += 2;
        }
        let mut position = 0usize;
        while position < unique_count && compare_word(input, start, token_length, entries[position]).is_gt() { position += 1; }
        if position < unique_count && compare_word(input, start, token_length, entries[position]).is_eq() {
            entries[position].count += 1;
        } else {
            for move_index in (position..unique_count).rev() { entries[move_index + 1] = entries[move_index]; }
            entries[position] = WordEntry { start, length: token_length, count: 1 }; unique_count += 1;
        }
    }
    let required: usize = entries[..unique_count].iter().map(|entry| {
        let digits = entry.count.to_string().len(); entry.length + digits + 2
    }).sum();
    if output_capacity < required || (required != 0 && output.is_null()) { return -2; }
    let output = if required == 0 { &mut [][..] } else { std::slice::from_raw_parts_mut(output, required) };
    let mut written = 0usize;
    for entry in entries[..unique_count].iter() {
        for offset in 0..entry.length { output[written] = lower_byte(input, entry.start + offset); written += 1; }
        written = write_count(output, written, entry.count);
    }
    written as i64
}
