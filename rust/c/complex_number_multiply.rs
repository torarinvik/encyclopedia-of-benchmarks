const MAX_TEXT_LENGTH: usize = 64;
const MAX_INPUT_LENGTH: usize = 130;
const MAX_COMPONENT: i64 = 32_767;

fn parse_component(bytes: &[i64]) -> Option<i64> {
    let (negative, digits) = if bytes.first() == Some(&45) {
        (true, &bytes[1..])
    } else {
        (false, bytes)
    };
    if digits.is_empty() { return None; }
    let mut magnitude = 0_i64;
    for &byte in digits {
        if !(48..=57).contains(&byte) { return None; }
        let digit = byte - 48;
        if magnitude > (MAX_COMPONENT - digit) / 10 { return None; }
        magnitude = magnitude * 10 + digit;
    }
    Some(if negative { -magnitude } else { magnitude })
}

fn parse_complex(bytes: &[i64]) -> Option<(i64, i64)> {
    if !(4..=MAX_TEXT_LENGTH).contains(&bytes.len()) || bytes.last() != Some(&105) { return None; }
    let mut separator = None;
    for (index, &byte) in bytes[..bytes.len() - 1].iter().enumerate() {
        if byte == 43 {
            if separator.is_some() { return None; }
            separator = Some(index);
        }
    }
    let separator = separator?;
    let real = parse_component(&bytes[..separator])?;
    let imaginary = parse_component(&bytes[separator + 1..bytes.len() - 1])?;
    Some((real, imaginary))
}

fn decimal_length(value: i64) -> usize {
    let mut length = if value < 0 { 1 } else { 0 };
    let mut magnitude = if value < 0 { -value } else { value };
    if magnitude == 0 { return length + 1; }
    while magnitude > 0 { length += 1; magnitude /= 10; }
    length
}

fn append_decimal(output: &mut [u8], index: &mut usize, value: i64) {
    let mut magnitude = value;
    if magnitude < 0 {
        output[*index] = 45;
        *index += 1;
        magnitude = -magnitude;
    }
    let start = *index;
    if magnitude == 0 {
        output[*index] = 48;
        *index += 1;
        return;
    }
    while magnitude > 0 {
        output[*index] = (48 + magnitude % 10) as u8;
        *index += 1;
        magnitude /= 10;
    }
    let mut left = start;
    let mut right = *index - 1;
    while left < right {
        output.swap(left, right);
        left += 1;
        right -= 1;
    }
}

/// Multiply two bounded ASCII complex-number strings and emit the source format.
#[no_mangle]
pub unsafe extern "C" fn complex_number_multiply(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let (raw_left_length, raw_right_length) = (values[0], values[1]);
    if !(4..=MAX_TEXT_LENGTH as i64).contains(&raw_left_length)
        || !(4..=MAX_TEXT_LENGTH as i64).contains(&raw_right_length) { return -1; }
    let (left_length, right_length) = (raw_left_length as usize, raw_right_length as usize);
    if length != 2 + left_length + right_length { return -1; }
    let left_bytes = &values[2..2 + left_length];
    let right_bytes = &values[2 + left_length..];
    if left_bytes.iter().chain(right_bytes).any(|&byte| !(0..=127).contains(&byte)) { return -1; }
    let Some((left_real, left_imaginary)) = parse_complex(left_bytes) else { return -1; };
    let Some((right_real, right_imaginary)) = parse_complex(right_bytes) else { return -1; };

    let real = left_real * right_real - left_imaginary * right_imaginary;
    let imaginary = left_real * right_imaginary + left_imaginary * right_real;
    let needed = decimal_length(real) + decimal_length(imaginary) + 2;
    if output.is_null() || capacity < needed { return -2; }
    let result = std::slice::from_raw_parts_mut(output, needed);
    let mut written = 0;
    append_decimal(result, &mut written, real);
    result[written] = 43;
    written += 1;
    append_decimal(result, &mut written, imaginary);
    result[written] = 105;
    written += 1;
    written as i64
}
