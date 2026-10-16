const MAX_TEXT_BYTES: usize = 512;
const MAX_MASK_BYTES: usize = 16;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 531;
const MAX_OUTPUT_BYTES: usize = 1447;

const WORDS: [&[u8]; 3] = [b"birds", b"market", b"street"];
const NORMALIZED_VARIANTS: [&[u8]; 9] = [
    b"birds", b"BIRDS", b"Birds", b"market", b"MARKET", b"Market",
    b"street", b"STREET", b"Street",
];

fn is_word(value: u8) -> bool {
    value.is_ascii_alphanumeric() || value == b'_'
}

fn is_normalized_target(token: &[u8]) -> bool {
    NORMALIZED_VARIANTS.iter().any(|variant| *variant == token)
}

fn match_length(text: &[u8], start: usize, end: usize, position: usize) -> usize {
    for word in WORDS {
        let length = word.len();
        if position + length <= end
            && &text[position..position + length] == word
            && (position == start || !is_word(text[position - 1]))
            && (position + length == end || !is_word(text[position + length]))
        {
            return length;
        }
    }
    0
}

fn append_token(
    text: &[u8],
    start: usize,
    end: usize,
    mask: &[u8],
    output: &mut [u8; MAX_OUTPUT_BYTES],
    mut written: usize,
) -> usize {
    if is_normalized_target(&text[start..end]) {
        for &byte in mask {
            output[written] = byte;
            written += 1;
        }
        return written;
    }
    let mut position = start;
    while position < end {
        let matched = match_length(text, start, end, position);
        if matched != 0 {
            for &byte in mask {
                output[written] = byte;
                written += 1;
            }
            position += matched;
        } else {
            if text[position] != b'\n' {
                output[written] = text[position];
                written += 1;
            }
            position += 1;
        }
    }
    written
}

#[no_mangle]
pub unsafe extern "C" fn maskwords(
    values: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if values.is_null() || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH {
        return -1;
    }
    let input = std::slice::from_raw_parts(values, length);
    if input[0] < 0 || input[0] > MAX_TEXT_BYTES as i64 {
        return -1;
    }
    let text_length = input[0] as usize;
    let mask_length_index = 1 + text_length;
    if mask_length_index >= length
        || input[mask_length_index] < 0
        || input[mask_length_index] > MAX_MASK_BYTES as i64
    {
        return -1;
    }
    let mask_length = input[mask_length_index] as usize;
    if length != mask_length_index + 1 + mask_length {
        return -1;
    }

    let mut text_storage = [0u8; MAX_TEXT_BYTES];
    let mut mask_storage = [0u8; MAX_MASK_BYTES];
    for i in 0..text_length {
        let value = input[1 + i];
        if !(1..=127).contains(&value) {
            return -1;
        }
        text_storage[i] = value as u8;
    }
    for i in 0..mask_length {
        let value = input[mask_length_index + 1 + i];
        if !(32..=126).contains(&value) || value == b'\\' as i64 {
            return -1;
        }
        mask_storage[i] = value as u8;
    }
    let text = &text_storage[..text_length];
    let mask = &mask_storage[..mask_length];

    let mut scratch = [0u8; MAX_OUTPUT_BYTES];
    let mut written = 0usize;
    let mut start = 0usize;
    let mut have_token = false;
    for i in 0..text_length {
        if text[i] == b' ' {
            if have_token {
                scratch[written] = b' ';
                written += 1;
            }
            written = append_token(text, start, i, mask, &mut scratch, written);
            have_token = true;
            start = i + 1;
        }
    }
    if start < text_length {
        if have_token {
            scratch[written] = b' ';
            written += 1;
        }
        written = append_token(text, start, text_length, mask, &mut scratch, written);
    }
    if written > MAX_OUTPUT_BYTES {
        return -1;
    }
    if output_capacity < written || (written != 0 && output.is_null()) {
        return -2;
    }
    if written != 0 {
        std::ptr::copy_nonoverlapping(scratch.as_ptr(), output, written);
    }
    written as i64
}
