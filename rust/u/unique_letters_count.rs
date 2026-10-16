const MAX_TEXT_LENGTH: usize = 256;
const MAX_INPUT_LENGTH: usize = MAX_TEXT_LENGTH + 1;
const LETTER_COUNT: usize = 26;
const BYTES_PER_RECORD: usize = 8;

#[no_mangle]
pub unsafe extern "C" fn unique_letters_count(
    input: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT_LENGTH { return -1; }
    let packed = std::slice::from_raw_parts(input, length);
    if !(0..=MAX_TEXT_LENGTH as i64).contains(&packed[0]) || length != 1 + packed[0] as usize {
        return -1;
    }
    let text = &packed[1..];
    if text.iter().any(|byte| !(0..=127).contains(byte)) { return -1; }

    let mut frequencies = [0i32; LETTER_COUNT];
    let mut first_seen = [0i32; LETTER_COUNT];
    let mut unique_count = 0usize;
    for &raw_byte in text {
        let mut byte = raw_byte as i64;
        if (65..=90).contains(&byte) {
            byte += 32;
        } else if !(97..=122).contains(&byte) {
            continue;
        }
        let letter_index = (byte - 97) as usize;
        if frequencies[letter_index] == 0 {
            first_seen[unique_count] = byte as i32;
            unique_count += 1;
        }
        frequencies[letter_index] += 1;
    }

    let required_capacity = text.len().min(LETTER_COUNT) * BYTES_PER_RECORD;
    if output_capacity < required_capacity || (required_capacity > 0 && output.is_null()) { return -2; }
    for index in 0..unique_count {
        let letter = first_seen[index];
        std::ptr::copy_nonoverlapping(letter.to_le_bytes().as_ptr(), output.add(index * BYTES_PER_RECORD), 4);
        let count = frequencies[(letter - 97) as usize];
        std::ptr::copy_nonoverlapping(count.to_le_bytes().as_ptr(), output.add(index * BYTES_PER_RECORD + 4), 4);
    }
    unique_count as i64
}
