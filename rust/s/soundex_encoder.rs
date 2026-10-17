const MAX_TEXT_LENGTH: usize = 64;
const MAX_INPUT_LENGTH: usize = MAX_TEXT_LENGTH + 1;
const MAX_PARSEABLE_INPUT_LENGTH: usize = MAX_INPUT_LENGTH + 2;
const MAX_OUTPUT_BYTES: usize = 4;

fn is_ascii_letter(value: i64) -> bool {
    (65..=90).contains(&value) || (97..=122).contains(&value)
}

fn digit_for(input_value: i64) -> i64 {
    let value = if (65..=90).contains(&input_value) { input_value + 32 } else { input_value };
    match value {
        97 | 101 | 105 | 111 | 117 | 121 => 0,
        104 | 119 => 8,
        98 | 102 | 112 | 118 => 1,
        99 | 103 | 106 | 107 | 113 | 115 | 120 | 122 => 2,
        100 | 116 => 3,
        108 => 4,
        109 | 110 => 5,
        114 => 6,
        _ => -1,
    }
}

#[no_mangle]
pub unsafe extern "C" fn soundex_encoder(
    values: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if length < 1 || length > MAX_PARSEABLE_INPUT_LENGTH || values.is_null() {
        return -1;
    }
    let input = std::slice::from_raw_parts(values, length);
    let text_length = input[0];
    if text_length < 1 || text_length > MAX_TEXT_LENGTH as i64 || length > MAX_INPUT_LENGTH ||
        length != text_length as usize + 1 { return -1; }
    if input[1..].iter().any(|value| !is_ascii_letter(*value)) { return -1; }

    let mut mapped = [0i64; MAX_TEXT_LENGTH];
    let mut mapped_count = 0usize;
    for value in input[1..].iter().copied() {
        let letter = if (65..=90).contains(&value) { value + 32 } else { value };
        if letter == 104 || letter == 119 { continue; }
        let digit = digit_for(letter);
        if mapped_count == 0 || mapped[mapped_count - 1] != digit {
            mapped[mapped_count] = digit;
            mapped_count += 1;
        }
    }

    let mut code_count = 0usize;
    for index in 0..mapped_count {
        if mapped[index] != 0 {
            mapped[code_count] = mapped[index];
            code_count += 1;
        }
    }
    if code_count == 0 { return -1; }

    let first_letter = if (65..=90).contains(&input[1]) { input[1] + 32 } else { input[1] };
    let mut start = 0usize;
    if mapped[0] == digit_for(first_letter) {
        if code_count == 1 { return -1; }
        start = 1;
    }

    let mut encoded = [0u8; MAX_OUTPUT_BYTES];
    encoded[0] = if (97..=122).contains(&input[1]) { (input[1] - 32) as u8 } else { input[1] as u8 };
    for index in 0..3 {
        let digit = if start + index < code_count { mapped[start + index] } else { 0 };
        encoded[index + 1] = (b'0' as i64 + digit) as u8;
    }

    if output.is_null() || output_capacity < MAX_OUTPUT_BYTES { return -2; }
    std::ptr::copy_nonoverlapping(encoded.as_ptr(), output, MAX_OUTPUT_BYTES);
    MAX_OUTPUT_BYTES as i64
}
