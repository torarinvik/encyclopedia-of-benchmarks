const MAX_INPUT_VALUES: usize = 512;

unsafe fn count_matches(values: &[i64], text_length: usize, pattern_length: usize,
                        pattern_start: usize, shifts: &[usize; 128]) -> usize {
    if pattern_length == 0 { return text_length + 1; }
    if pattern_length > text_length { return 0; }
    let mut count = 0;
    let mut start = 0;
    while start <= text_length - pattern_length {
        let mut current = pattern_length;
        while current > 0 && values[pattern_start + current - 1] == values[2 + start + current - 1] {
            current -= 1;
        }
        if current == 0 {
            count += 1;
            start += 1;
        } else {
            start += shifts[values[2 + start + pattern_length - 1] as usize];
        }
    }
    count
}

#[no_mangle]
pub unsafe extern "C" fn boyer_moore_horspool(
    values: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if values.is_null() || !(2..=MAX_INPUT_VALUES).contains(&length) { return -1; }
    if !((0..=255).contains(&*values) && (0..=255).contains(&*values.add(1))) { return -1; }
    let values = std::slice::from_raw_parts(values, length);
    let text_length = values[0] as usize;
    let pattern_length = values[1] as usize;
    if length != 2 + text_length + pattern_length { return -1; }
    let pattern_start = 2 + text_length;
    if values[2..].iter().any(|&byte| !(0..=127).contains(&byte)) { return -1; }

    let mut shifts = [pattern_length; 128];
    for index in 0..pattern_length.saturating_sub(1) {
        shifts[values[pattern_start + index] as usize] = pattern_length - 1 - index;
    }
    let match_count = count_matches(values, text_length, pattern_length, pattern_start, &shifts);
    if output_capacity < match_count || (match_count != 0 && output.is_null()) { return -2; }

    let mut written = 0;
    if pattern_length == 0 {
        for position in 0..=text_length {
            *output.add(written) = position as u8;
            written += 1;
        }
    } else if pattern_length <= text_length {
        let mut start = 0;
        while start <= text_length - pattern_length {
            let mut current = pattern_length;
            while current > 0 && values[pattern_start + current - 1] == values[2 + start + current - 1] {
                current -= 1;
            }
            if current == 0 {
                *output.add(written) = start as u8;
                written += 1;
                start += 1;
            } else {
                start += shifts[values[2 + start + pattern_length - 1] as usize];
            }
        }
    }
    written as i64
}
