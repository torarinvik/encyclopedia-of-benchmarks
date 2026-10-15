const MAX_LENGTH: usize = 1024;

fn lower_ascii(value: i64) -> i64 {
    if (65..=90).contains(&value) { value + 32 } else { value }
}

#[no_mangle]
pub unsafe extern "C" fn check_palindrome2(
    values: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if length > MAX_LENGTH || (length != 0 && values.is_null()) { return -1; }
    let input = if length == 0 { &[][..] } else { std::slice::from_raw_parts(values, length) };
    if input.iter().any(|&value| !(32..=126).contains(&value)) { return -1; }
    let mut start = 0;
    let mut end = length;
    while start < end && input[start] == 32 { start += 1; }
    while end > start && input[end - 1] == 32 { end -= 1; }
    let normalized = &input[start..end];
    if normalized.is_empty() || (normalized.len() == 1 && normalized[0] == 48) { return -1; }

    let palindrome = (0..normalized.len() / 2).all(|left| {
        lower_ascii(normalized[left]) == lower_ascii(normalized[normalized.len() - left - 1])
    });
    let suffix: &[u8] = if palindrome {
        b" - a palindrome string.\n"
    } else {
        b" - not a palindrome string.\n"
    };
    let required = normalized.len() + suffix.len();
    if output.is_null() || output_capacity < required { return -2; }
    let result = std::slice::from_raw_parts_mut(output, output_capacity);
    for (index, &value) in normalized.iter().enumerate() {
        result[index] = lower_ascii(value) as u8;
    }
    result[normalized.len()..required].copy_from_slice(suffix);
    required as i64
}
