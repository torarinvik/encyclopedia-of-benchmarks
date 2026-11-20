/// Find all bounded byte-pattern matches with Tuned Boyer–Moore's skip loop.
const MAX_TEXT: usize = 255;
const MAX_PATTERN: usize = 64;
const MAX_FRAME: usize = 322;
const MAX_PADDED: usize = MAX_TEXT + MAX_PATTERN;

fn store_i64_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub extern "C" fn tuned_boyer_moore_search(input: *const i64, length: usize,
        output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_FRAME { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    if !(0..=MAX_TEXT as i64).contains(&values[0]) || !(1..=MAX_PATTERN as i64).contains(&values[1]) { return -1; }
    let n = values[0] as usize;
    let m = values[1] as usize;
    if length != 2 + n + m || values[2..].iter().any(|&value| !(0..=127).contains(&value)) { return -1; }
    let pattern_start = 2 + n;
    let mut positions = [0i64; MAX_TEXT];
    let mut match_count = 0usize;
    if m <= n {
        let mut padded = [0u8; MAX_PADDED];
        let mut shifts = [m; 128];
        let final_byte = values[pattern_start + m - 1] as u8;
        for i in 0..n { padded[i] = values[2 + i] as u8; }
        for i in 0..m { padded[n + i] = final_byte; }
        for i in 0..m - 1 { shifts[values[pattern_start + i] as usize] = m - i - 1; }
        let final_shift = shifts[final_byte as usize];
        shifts[final_byte as usize] = 0;
        let mut alignment = 0usize;
        while alignment < n {
            let mut skip = shifts[padded[alignment + m - 1] as usize];
            while skip != 0 {
                alignment += skip;
                skip = shifts[padded[alignment + m - 1] as usize];
                alignment += skip;
                skip = shifts[padded[alignment + m - 1] as usize];
                alignment += skip;
                skip = shifts[padded[alignment + m - 1] as usize];
            }
            let mut prefix_matches = true;
            for i in 0..m - 1 {
                if values[pattern_start + i] as u8 != padded[alignment + i] {
                    prefix_matches = false;
                    break;
                }
            }
            if prefix_matches && alignment < n {
                positions[match_count] = alignment as i64;
                match_count += 1;
            }
            alignment += final_shift;
        }
    }
    let output_bytes = match_count * 8;
    if output.is_null() || output_capacity < output_bytes { return -2; }
    let output = unsafe { std::slice::from_raw_parts_mut(output, output_bytes) };
    for i in 0..match_count { store_i64_le(output, i * 8, positions[i]); }
    output_bytes as i64
}
