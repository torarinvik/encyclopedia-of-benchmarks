const MAX_KEYWORD_LENGTH: usize = 64;
const MAX_PLAINTEXT_LENGTH: usize = 512;
const MAX_INPUT_LENGTH: usize = 2 + MAX_KEYWORD_LENGTH + MAX_PLAINTEXT_LENGTH;

#[no_mangle]
pub unsafe extern "C" fn mixed_keyword_cypher(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || !(2..=MAX_INPUT_LENGTH).contains(&length) {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);

    let raw_keyword_length = values[0];
    if !(1..=MAX_KEYWORD_LENGTH as i64).contains(&raw_keyword_length) {
        return -1;
    }
    let keyword_length = raw_keyword_length as usize;
    let plaintext_length_index = 1 + keyword_length;
    if plaintext_length_index >= length {
        return -1;
    }

    let raw_plaintext_length = values[plaintext_length_index];
    if !(0..=MAX_PLAINTEXT_LENGTH as i64).contains(&raw_plaintext_length) {
        return -1;
    }
    let plaintext_length = raw_plaintext_length as usize;
    if length != plaintext_length_index + 1 + plaintext_length {
        return -1;
    }

    let mut unique_letters = [0u8; 26];
    let mut seen = [false; 26];
    let mut unique_count = 0usize;
    for index in 0..keyword_length {
        let raw = values[1 + index];
        if !(0..=127).contains(&raw) {
            return -1;
        }
        let mut letter = raw as u8;
        if letter.is_ascii_lowercase() {
            letter -= b'a' - b'A';
        }
        if letter.is_ascii_uppercase() {
            let alphabet_index = usize::from(letter - b'A');
            if !seen[alphabet_index] {
                seen[alphabet_index] = true;
                unique_letters[unique_count] = letter;
                unique_count += 1;
            }
        }
    }
    if unique_count == 0 {
        return -1;
    }

    for index in 0..plaintext_length {
        let raw = values[plaintext_length_index + 1 + index];
        if !(0..=127).contains(&raw) {
            return -1;
        }
    }

    let mut shifted = [0u8; 26];
    shifted[..unique_count].copy_from_slice(&unique_letters[..unique_count]);
    let mut shifted_count = unique_count;
    for index in 0..26 {
        if !seen[index] {
            shifted[shifted_count] = b'A' + index as u8;
            shifted_count += 1;
        }
    }

    let mut mapping = [0u8; 26];
    let mut alphabet_index = 0usize;
    for column in 0..unique_count {
        let mut row_start = 0usize;
        while row_start < 26 {
            let shifted_index = row_start + column;
            if shifted_index >= 26 {
                break;
            }
            mapping[alphabet_index] = shifted[shifted_index];
            alphabet_index += 1;
            row_start += unique_count;
        }
    }

    let mut buffer = [0u8; MAX_PLAINTEXT_LENGTH];
    for index in 0..plaintext_length {
        let mut letter = values[plaintext_length_index + 1 + index] as u8;
        if letter.is_ascii_lowercase() {
            letter -= b'a' - b'A';
        }
        buffer[index] = if letter.is_ascii_uppercase() {
            mapping[usize::from(letter - b'A')]
        } else {
            letter
        };
    }

    if output.is_null() || capacity < plaintext_length {
        return -2;
    }
    std::ptr::copy_nonoverlapping(buffer.as_ptr(), output, plaintext_length);
    plaintext_length as i64
}
