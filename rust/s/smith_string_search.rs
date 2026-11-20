/// Find all bounded byte-pattern matches with Smith's combined shift rule.
const MAX_TEXT: usize = 255;
const MAX_PATTERN: usize = 64;
const MAX_FRAME: usize = 322;

fn store_i64_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub extern "C" fn smith_string_search(input: *const i64, length: usize,
        output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_FRAME { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    if !(0..=MAX_TEXT as i64).contains(&values[0]) || !(1..=MAX_PATTERN as i64).contains(&values[1]) { return -1; }
    let n = values[0] as usize;
    let m = values[1] as usize;
    if length != 2 + n + m || values[2..].iter().any(|&value| !(0..=127).contains(&value)) { return -1; }

    let mut positions = [0i64; MAX_TEXT];
    let mut match_count = 0usize;
    if m <= n {
        let pattern_start = 2 + n;
        let mut horspool = [m; 128];
        let mut quick_search = [m + 1; 128];
        for i in 0..m - 1 { horspool[values[pattern_start + i] as usize] = m - i - 1; }
        for i in 0..m { quick_search[values[pattern_start + i] as usize] = m - i; }

        let last_alignment = n - m;
        let mut alignment = 0usize;
        while alignment <= last_alignment {
            let mut matches = true;
            for i in 0..m {
                if values[pattern_start + i] != values[2 + alignment + i] {
                    matches = false;
                    break;
                }
            }
            if matches {
                positions[match_count] = alignment as i64;
                match_count += 1;
            }
            let end_byte = values[2 + alignment + m - 1] as usize;
            let lookahead = alignment + m;
            let quick_shift = if lookahead < n { quick_search[values[2 + lookahead] as usize] } else { m + 1 };
            alignment += horspool[end_byte].max(quick_shift);
        }
    }
    let output_bytes = match_count * 8;
    if output.is_null() || output_capacity < output_bytes { return -2; }
    let output = unsafe { std::slice::from_raw_parts_mut(output, output_bytes) };
    for i in 0..match_count { store_i64_le(output, i * 8, positions[i]); }
    output_bytes as i64
}
