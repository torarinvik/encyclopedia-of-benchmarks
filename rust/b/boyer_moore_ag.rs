fn collect_matches(values: &[i64], text_length: usize, pattern_length: usize,
                   pattern_start: usize, positions: &mut [u8; 255]) -> usize {
    let mut bad_shift = [0usize; 128];
    let mut present = [false; 128];
    let mut suffix_skip = [0usize; 256];
    for index in 0..pattern_length.saturating_sub(1) {
        let byte = values[pattern_start + index] as usize;
        bad_shift[byte] = pattern_length - index - 1;
        present[byte] = true;
    }
    for byte in 0..128 {
        if !present[byte] { continue; }
        let shift = bad_shift[byte];
        let mut matched = 0;
        while matched < pattern_length - shift &&
              values[pattern_start + pattern_length - 1 - matched] ==
                  values[pattern_start + pattern_length - 1 - shift - matched] {
            matched += 1;
        }
        suffix_skip[shift] = matched;
    }

    let mut count = 0;
    let mut start = 0;
    let mut jump = pattern_length;
    while start <= text_length - pattern_length {
        let skip = suffix_skip[jump];
        let mut index = pattern_length as isize - 1;
        while index >= 0 {
            let offset = index as usize;
            if values[2 + start + offset] != values[pattern_start + offset] {
                let mismatch = values[2 + start + offset] as usize;
                jump = if present[mismatch] { bad_shift[mismatch] } else { pattern_length };
                start += jump;
                break;
            }
            if offset == pattern_length - jump { index -= skip as isize; }
            if index == 0 {
                positions[count] = start as u8;
                count += 1;
                jump = 1;
                start += 1;
                break;
            }
            index -= 1;
        }
    }
    count
}

#[no_mangle]
pub unsafe extern "C" fn boyer_moore_ag(
    values: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if values.is_null() || !(2..=512).contains(&length) { return -1; }
    if !(0..=255).contains(&*values) || !(1..=255).contains(&*values.add(1)) { return -1; }
    let values = std::slice::from_raw_parts(values, length);
    let text_length = values[0] as usize;
    let pattern_length = values[1] as usize;
    if length != 2 + text_length + pattern_length ||
       values[2..].iter().any(|&byte| !(0..=127).contains(&byte)) { return -1; }
    let mut positions = [0u8; 255];
    let count = if pattern_length > text_length { 0 } else {
        collect_matches(values, text_length, pattern_length, 2 + text_length, &mut positions)
    };
    if output_capacity < count || (count != 0 && output.is_null()) { return -2; }
    for index in 0..count { *output.add(index) = positions[index]; }
    count as i64
}
