#[no_mangle]
pub unsafe extern "C" fn naive_search(
    values: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if values.is_null() || !(2..=512).contains(&length) {
        return -1;
    }
    if !(0..=255).contains(&*values) || !(0..=255).contains(&*values.add(1)) {
        return -1;
    }
    let text_length = *values as usize;
    let pattern_length = *values.add(1) as usize;
    if length != 2 + text_length + pattern_length {
        return -1;
    }
    let values = std::slice::from_raw_parts(values, length);
    let text = &values[2..2 + text_length];
    let pattern = &values[2 + text_length..];
    if text.iter().chain(pattern.iter()).any(|&byte| !(1..=127).contains(&byte)) {
        return -1;
    }

    let mut match_count = 0usize;
    if pattern_length <= text_length {
        for start in 0..=text_length - pattern_length {
            if text[start..start + pattern_length] == pattern[..] {
                match_count += 1;
            }
        }
    }
    if output_capacity < match_count || (match_count != 0 && output.is_null()) {
        return -2;
    }
    let mut written = 0usize;
    if pattern_length <= text_length {
        for start in 0..=text_length - pattern_length {
            if text[start..start + pattern_length] == pattern[..] {
                *output.add(written) = start as u8;
                written += 1;
            }
        }
    }
    written as i64
}
