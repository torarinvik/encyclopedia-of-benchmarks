/// Find all overlapping matches using Raita's Horspool-based probe order.
const MAX_TEXT: usize = 255;
const MAX_PATTERN: usize = 64;
const MAX_FRAME: usize = 322;

fn store_i64_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub extern "C" fn raita_search(input: *const i64, length: usize,
        output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_FRAME { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    if !(0..=MAX_TEXT as i64).contains(&values[0]) || !(1..=MAX_PATTERN as i64).contains(&values[1]) { return -1; }
    let n = values[0] as usize;
    let m = values[1] as usize;
    if length != 2 + n + m || values[2..].iter().any(|&value| !(0..=127).contains(&value)) { return -1; }
    let text = &values[2..2 + n];
    let pattern = &values[2 + n..];

    let mut positions = [0i64; MAX_TEXT];
    let mut match_count = 0usize;
    if m <= n {
        let mut shifts = [m; 128];
        for index in 0..m - 1 { shifts[pattern[index] as usize] = m - index - 1; }
        let middle = m / 2;
        let mut alignment = 0usize;
        while alignment <= n - m {
            let last = text[alignment + m - 1] as usize;
            let mut matches = pattern[m - 1] == text[alignment + m - 1];
            if matches { matches = pattern[0] == text[alignment]; }
            if matches { matches = pattern[middle] == text[alignment + middle]; }
            if matches {
                let mut index = 1usize;
                while index + 1 < m && matches {
                    if pattern[index] != text[alignment + index] { matches = false; }
                    index += 1;
                }
                if matches {
                    positions[match_count] = alignment as i64;
                    match_count += 1;
                }
            }
            alignment += shifts[last];
        }
    }
    let output_bytes = match_count * 8;
    if output.is_null() || output_capacity < output_bytes { return -2; }
    let output = unsafe { std::slice::from_raw_parts_mut(output, output_bytes) };
    for index in 0..match_count { store_i64_le(output, index * 8, positions[index]); }
    output_bytes as i64
}
