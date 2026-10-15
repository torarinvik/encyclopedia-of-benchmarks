/// Parse an ASCII base-2 integer, add three, and format with minimum width four.
const MAX_TEXT_LENGTH: usize = 128;
const MAX_MAGNITUDE: i64 = 4_611_686_018_427_387_904;

fn is_ascii_space(value: i64) -> bool {
    value == 32 || (9..=13).contains(&value)
}

fn is_binary_digit(value: i64) -> bool {
    value == b'0' as i64 || value == b'1' as i64
}

#[no_mangle]
pub unsafe extern "C" fn binary_to_excess3(
    values: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if values.is_null() || length == 0 || length > MAX_TEXT_LENGTH { return -1; }
    let mut start = 0usize;
    let mut end = length;
    while start < end && is_ascii_space(*values.add(start)) { start += 1; }
    while end > start && is_ascii_space(*values.add(end - 1)) { end -= 1; }
    if start == end { return -1; }

    let mut negative = false;
    let first = *values.add(start);
    if first == b'+' as i64 || first == b'-' as i64 {
        negative = first == b'-' as i64;
        start += 1;
        if start == end { return -1; }
    }
    let prefixed = end - start >= 2 && *values.add(start) == b'0' as i64 &&
        (*values.add(start + 1) == b'b' as i64 || *values.add(start + 1) == b'B' as i64);
    if prefixed { start += 2; }
    if start == end { return -1; }

    let digit_start = start;
    let mut allow_prefix_underscore = prefixed;
    let mut have_digit = false;
    let mut last_was_digit = false;
    let mut magnitude = 0i64;
    for index in start..end {
        let value = *values.add(index);
        if is_binary_digit(value) {
            let digit = value - b'0' as i64;
            if magnitude > (MAX_MAGNITUDE - digit) / 2 { return -1; }
            magnitude = magnitude * 2 + digit;
            have_digit = true;
            last_was_digit = true;
            allow_prefix_underscore = false;
        } else if value == b'_' as i64 {
            if last_was_digit && index + 1 < end && is_binary_digit(*values.add(index + 1)) {
                last_was_digit = false;
            } else if allow_prefix_underscore && !have_digit && index == digit_start &&
                index + 1 < end && is_binary_digit(*values.add(index + 1)) {
                allow_prefix_underscore = false;
            } else {
                return -1;
            }
        } else {
            return -1;
        }
    }
    if !have_digit || !last_was_digit { return -1; }

    let mut result = (if negative { -magnitude } else { magnitude }) + 3;
    let result_is_negative = result < 0;
    let mut remaining = if result_is_negative { -result } else { result };
    let mut reversed = [0u8; 64];
    let mut digit_count = 0usize;
    loop {
        reversed[digit_count] = b'0' + (remaining % 2) as u8;
        digit_count += 1;
        remaining /= 2;
        if remaining == 0 { break; }
    }

    let sign_length = if result_is_negative { 1usize } else { 0usize };
    let output_length = (sign_length + digit_count).max(4);
    if output.is_null() || output_capacity < output_length { return -2; }
    let mut position = 0usize;
    if result_is_negative {
        *output.add(position) = b'-';
        position += 1;
    }
    let digit_width = output_length - sign_length;
    for _ in digit_count..digit_width {
        *output.add(position) = b'0';
        position += 1;
    }
    for index in (0..digit_count).rev() {
        *output.add(position) = reversed[index];
        position += 1;
    }
    output_length as i64
}
