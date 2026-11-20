/// Find every overlapping occurrence with bounded Turbo Boyer–Moore search.
const MAX_TEXT: usize = 255;
const MAX_PATTERN: usize = 64;
const MAX_FRAME: usize = 322;

fn good_suffix(pattern: &[i64], shifts: &mut [usize]) {
    let length = pattern.len();
    let mut suffix = [0usize; MAX_PATTERN];
    suffix[length - 1] = length;
    let mut g = length as isize - 1;
    let mut f = 0isize;
    let mut index = length as isize - 2;
    while index >= 0 {
        if index > g && suffix[(index + length as isize - 1 - f) as usize] < (index - g) as usize {
            suffix[index as usize] = suffix[(index + length as isize - 1 - f) as usize];
        } else {
            if index < g { g = index; }
            f = index;
            while g >= 0 && pattern[g as usize] == pattern[(g + length as isize - 1 - f) as usize] { g -= 1; }
            suffix[index as usize] = (f - g) as usize;
        }
        index -= 1;
    }
    shifts.fill(length);
    let mut border = 0usize;
    index = length as isize - 1;
    while index >= 0 {
        if suffix[index as usize] == index as usize + 1 {
            while border < length - 1 - index as usize {
                if shifts[border] == length { shifts[border] = length - 1 - index as usize; }
                border += 1;
            }
        }
        index -= 1;
    }
    for i in 0..length - 1 { shifts[length - 1 - suffix[i]] = length - 1 - i; }
}

#[no_mangle]
pub extern "C" fn turbo_boyer_moore_search(input: *const i64, length: usize,
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
        let mut bad = [m; 128];
        for i in 0..m - 1 { bad[pattern[i] as usize] = m - i - 1; }
        let mut good = [0usize; MAX_PATTERN];
        good_suffix(pattern, &mut good[..m]);
        let mut alignment = 0usize;
        let mut remembered = 0usize;
        let mut shift = m;
        while alignment <= n - m {
            let mut i = m as isize - 1;
            while i >= 0 && pattern[i as usize] == text[alignment + i as usize] {
                i -= 1;
                if remembered != 0 && i == m as isize - 1 - shift as isize { i -= remembered as isize; }
            }
            if i < 0 {
                positions[match_count] = alignment as i64;
                match_count += 1;
                shift = good[0];
                remembered = m - shift;
            } else {
                let matched = m - 1 - i as usize;
                let turbo_shift = remembered as isize - matched as isize;
                let bad_shift = bad[text[alignment + i as usize] as usize] as isize - m as isize + 1 + i;
                let gs = good[i as usize];
                shift = turbo_shift.max(bad_shift).max(gs as isize) as usize;
                if shift == gs {
                    remembered = (m - shift).min(matched);
                } else {
                    if turbo_shift < bad_shift { shift = shift.max(remembered + 1); }
                    remembered = 0;
                }
            }
            alignment += shift;
        }
    }
    let output_bytes = match_count * 8;
    if output.is_null() || output_capacity < output_bytes { return -2; }
    let output = unsafe { std::slice::from_raw_parts_mut(output, output_bytes) };
    for i in 0..match_count { output[i * 8..i * 8 + 8].copy_from_slice(&positions[i].to_le_bytes()); }
    output_bytes as i64
}
