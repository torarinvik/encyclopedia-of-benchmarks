const MAX_TEXT: usize = 4096;
const MAX_PATTERN: usize = 128;
const MAX_INPUT: usize = 4227;

fn advance_maximal_suffix(segment: &[i64], left: &mut isize, right: &mut isize,
                          offset: &mut isize, period: &mut isize) {
    while *right + *offset < segment.len() as isize {
        let a = segment[(*left + *offset) as usize];
        let b = segment[(*right + *offset) as usize];
        if a == b {
            if *offset == *period {
                *right += *period;
                *offset = 1;
            } else {
                *offset += 1;
            }
        } else if a > b {
            *right += *offset;
            *offset = 1;
            *period = *right - *left;
        } else {
            *left = *right;
            *right += 1;
            *offset = 1;
            *period = 1;
        }
    }
}

fn prefix_repeats(segment: &[i64], shift: isize, last_index: isize) -> bool {
    for q in 0..=last_index {
        if segment[q as usize] != segment[(shift + q) as usize] { return false; }
    }
    true
}

fn execute(input: &[i64]) -> Result<i64, ()> {
    if input.len() < 2 || input.len() > MAX_INPUT { return Err(()); }
    let (n64, m64) = (input[0], input[1]);
    if n64 < 0 || n64 > MAX_TEXT as i64 || m64 < 1 || m64 > MAX_PATTERN as i64 { return Err(()); }
    let (n, m) = (n64 as usize, m64 as usize);
    if input.len() != 2 + n + m { return Err(()); }
    let pattern_start = 2 + n;
    if input[2..pattern_start].iter().any(|&value| !(0..=3).contains(&value)) ||
        input[pattern_start..].iter().any(|&value| !(0..=3).contains(&value)) { return Err(()); }
    if n < m { return Ok(0); }

    let mut alignment = 0isize;
    let mut matched = 0isize;
    let (mut suffix_left, mut suffix_right, mut suffix_offset, mut period) = (-1isize, 0isize, 1isize, 1isize);
    let (mut count, mut offset_sum, mut offset_xor) = (0i64, 0i64, 0i64);
    while alignment <= (n - m) as isize {
        while alignment + matched < n as isize && matched < m as isize &&
            input[pattern_start + matched as usize] == input[2 + (alignment + matched) as usize] {
            matched += 1;
        }
        if matched == 0 {
            alignment += 1;
            suffix_left = -1; suffix_right = 0; suffix_offset = 1; period = 1;
            continue;
        }
        if matched == m as isize {
            count += 1;
            offset_sum += alignment as i64;
            offset_xor ^= alignment as i64;
            if alignment == (n - m) as isize { break; }
        }

        let segment_start = 2 + alignment as usize;
        let segment_end = segment_start + matched as usize + 1;
        let segment = &input[segment_start..segment_end];
        advance_maximal_suffix(segment, &mut suffix_left, &mut suffix_right,
                               &mut suffix_offset, &mut period);
        let reusable = suffix_left < 0 ||
            (suffix_left < period && prefix_repeats(segment, period, suffix_left));
        if reusable {
            alignment += period;
            matched -= period;
            if matched < 0 { matched = 0; }
            if suffix_right - suffix_left > period {
                suffix_right -= period;
            } else {
                suffix_left = -1; suffix_right = 0; suffix_offset = 1; period = 1;
            }
        } else {
            let conservative = (matched - suffix_left - 1).min(suffix_right + 1);
            let certified = (suffix_left + 1).max(conservative);
            alignment += certified + 1;
            matched = 0;
            suffix_left = -1; suffix_right = 0; suffix_offset = 1; period = 1;
        }
    }
    Ok((count << 36) | (offset_sum << 12) | offset_xor)
}

#[no_mangle]
pub unsafe extern "C" fn string_matching_ordered_alphabets(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    execute(std::slice::from_raw_parts(input, length)).unwrap_or(-1)
}
