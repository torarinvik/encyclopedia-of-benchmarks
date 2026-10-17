const MAX_TEXT_LENGTH: i64 = 256;
const MAX_INPUT_LENGTH: usize = 258;
const WORD_BANK: [&[u8]; 24] = [
    b"I ", b"You ", b"We ", b"They ", b"He ", b"She ", b"It ", b" the ",
    b"The ", b" of ", b" is ", b"Is ", b" am ", b"Am ", b" are ", b"Are ",
    b" have ", b"Have ", b" has ", b"Has ", b" may ", b"May ", b" be ", b"Be ",
];

fn shift_ascii_letter(code: i64, key: i64) -> i64 {
    if (65..=90).contains(&code) {
        return 65 + (code - 65 + key) % 26;
    }
    if (97..=122).contains(&code) {
        return 97 + (code - 97 + key) % 26;
    }
    code
}

#[no_mangle]
pub unsafe extern "C" fn key_finder(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT_LENGTH {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    let text_length_value = values[0];
    if !(0..=MAX_TEXT_LENGTH).contains(&text_length_value) {
        return -1;
    }
    let text_length = text_length_value as usize;
    if length != text_length + 1 {
        return -1;
    }
    if values[1..].iter().any(|&code| {
        !(32..=126).contains(&code) || (48..=57).contains(&code)
    }) {
        return -1;
    }

    for key in 0..26 {
        for start in 0..text_length {
            for phrase in WORD_BANK {
                if start + phrase.len() > text_length {
                    continue;
                }
                let matches = phrase.iter().enumerate().all(|(offset, &expected)| {
                    shift_ascii_letter(values[start + offset + 1], key) == i64::from(expected)
                });
                if matches {
                    return key;
                }
            }
        }
    }
    0
}
