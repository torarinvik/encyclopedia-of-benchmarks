#[no_mangle]
pub unsafe extern "C" fn minimum_window_subsequence(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 3 || length > 258 {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    if !(0..=128).contains(&values[0]) {
        return -1;
    }
    let search_length = values[0] as usize;
    let pattern_length_index = search_length + 1;
    if length <= pattern_length_index {
        return -1;
    }
    let pattern_length_value = values[pattern_length_index];
    if !(1..=128).contains(&pattern_length_value) {
        return -1;
    }
    let pattern_length = pattern_length_value as usize;
    if length != search_length + pattern_length + 2 {
        return -1;
    }
    if values[1..search_length + 1].iter().any(|&byte| !(0..=127).contains(&byte))
        || values[search_length + 2..].iter().any(|&byte| !(0..=127).contains(&byte))
    {
        return -1;
    }

    let mut latest_start = [-1i8; 128];
    let mut best_start: isize = -1;
    let mut best_length = search_length + 1;
    for end in 0..search_length {
        let byte = values[end + 1];
        for offset in 0..pattern_length {
            let pattern_index = pattern_length - 1 - offset;
            if byte != values[search_length + 2 + pattern_index] {
                continue;
            }
            let candidate = if pattern_index == 0 {
                end as isize
            } else {
                latest_start[pattern_index - 1] as isize
            };
            if candidate >= 0 && candidate > latest_start[pattern_index] as isize {
                latest_start[pattern_index] = candidate as i8;
            }
        }
        if byte == values[search_length + 2 + pattern_length - 1]
            && latest_start[pattern_length - 1] >= 0
        {
            let start = latest_start[pattern_length - 1] as usize;
            let window_length = end - start + 1;
            if window_length < best_length
                || (window_length == best_length && (best_start < 0 || (start as isize) < best_start))
            {
                best_start = start as isize;
                best_length = window_length;
            }
        }
    }
    if best_start < 0 {
        return 0;
    }
    if best_length > capacity || output.is_null() {
        return -2;
    }
    for i in 0..best_length {
        *output.add(i) = values[best_start as usize + 1 + i] as u8;
    }
    best_length as i64
}
