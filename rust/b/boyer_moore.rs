/// Return the first ASCII byte match using bad-character and good-suffix shifts.
#[no_mangle]
pub extern "C" fn boyer_moore(input_values: *const i64, length: usize) -> i64 {
    if input_values.is_null() || length < 2 || length > 8194 {
        return -1;
    }
    let values = unsafe { std::slice::from_raw_parts(input_values, length) };
    if !(0..=4096).contains(&values[0]) || !(0..=4096).contains(&values[1]) {
        return -1;
    }
    let text_length = values[0] as usize;
    let pattern_length = values[1] as usize;
    if length != 2 + text_length + pattern_length
        || values[2..].iter().any(|&value| !(0..=126).contains(&value))
    {
        return -1;
    }
    if pattern_length == 0 {
        return 0;
    }
    if pattern_length > text_length {
        return -1;
    }

    let pattern_start = 2 + text_length;
    let mut last_occurrence = [-1isize; 127];
    for index in 0..pattern_length {
        last_occurrence[values[pattern_start + index] as usize] = index as isize;
    }

    let mut good_suffix = vec![0usize; 4097];
    let mut border_position = vec![0usize; 4097];
    let mut i = pattern_length;
    let mut j = pattern_length + 1;
    border_position[i] = j;
    while i > 0 {
        while j <= pattern_length && values[pattern_start + i - 1] != values[pattern_start + j - 1] {
            if good_suffix[j] == 0 {
                good_suffix[j] = j - i;
            }
            j = border_position[j];
        }
        i -= 1;
        j -= 1;
        border_position[i] = j;
    }
    j = border_position[0];
    for i in 0..=pattern_length {
        if good_suffix[i] == 0 {
            good_suffix[i] = j;
        }
        if i == j {
            j = border_position[j];
        }
    }

    let mut alignment = 0usize;
    while alignment <= text_length - pattern_length {
        let mut pattern_index = pattern_length;
        while pattern_index > 0
            && values[pattern_start + pattern_index - 1] == values[2 + alignment + pattern_index - 1]
        {
            pattern_index -= 1;
        }
        if pattern_index == 0 {
            return alignment as i64;
        }
        let text_byte = values[2 + alignment + pattern_index - 1] as usize;
        let bad_shift = ((pattern_index - 1) as isize - last_occurrence[text_byte]).max(1) as usize;
        alignment += good_suffix[pattern_index].max(bad_shift);
    }
    -1
}
