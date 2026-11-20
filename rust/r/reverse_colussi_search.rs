const MAX_TEXT: usize = 4096;
const MAX_PATTERN: usize = 128;
const MAX_INPUT: usize = 4227;

fn execute(input: &[i64]) -> Result<i64, ()> {
    if input.len() < 2 || input.len() > MAX_INPUT { return Err(()); }
    let (n64, m64) = (input[0], input[1]);
    if n64 < 0 || n64 > MAX_TEXT as i64 || m64 < 1 || m64 > MAX_PATTERN as i64 { return Err(()); }
    let (n, m) = (n64 as usize, m64 as usize);
    if input.len() != 2 + n + m { return Err(()); }
    let mut text = [0u8; MAX_TEXT];
    let mut pattern = [0u8; MAX_PATTERN];
    for q in 0..n {
        let value = input[2 + q];
        if !(0..=3).contains(&value) { return Err(()); }
        text[q] = value as u8;
    }
    for q in 0..m {
        let value = input[2 + n + q];
        if !(0..=3).contains(&value) { return Err(()); }
        pattern[q] = value as u8;
    }
    if n < m { return Ok(0); }

    let mut hmin = [0i32; MAX_PATTERN + 1];
    let mut kmin = [0i32; MAX_PATTERN];
    let mut rmin = [0i32; MAX_PATTERN];
    let mut order = [0usize; MAX_PATTERN];
    let mut good_suffix = [0i32; MAX_PATTERN + 1];
    let mut bad_character = [[0i32; MAX_PATTERN + 1]; 4];
    for shift in 1..=m {
        let mut last_mismatch = shift - 1;
        for pos in shift..m {
            if pattern[pos] != pattern[pos - shift] { last_mismatch = pos; }
        }
        hmin[shift] = last_mismatch as i32;
    }
    for shift in (1..=m).rev() {
        let end = hmin[shift] as usize;
        if end != m - 1 { kmin[end] = shift as i32; }
    }
    let mut next_boundary = m;
    for end in (0..m).rev() {
        if hmin[end + 1] == end as i32 { next_boundary = end + 1; }
        rmin[end] = next_boundary as i32;
    }
    order[0] = m - 1;
    let mut cursor = 0usize;
    for shift in 1..=m {
        let end = hmin[shift] as usize;
        if end != m - 1 && kmin[end] == shift as i32 {
            cursor += 1;
            order[cursor] = end;
            good_suffix[cursor] = shift as i32;
        }
    }
    cursor = m - 1;
    for end in (0..m.saturating_sub(1)).rev() {
        if kmin[end] == 0 {
            order[cursor] = end;
            good_suffix[cursor] = rmin[end];
            cursor -= 1;
        }
    }
    good_suffix[m] = rmin[0];

    for symbol in 0..4 {
        for prior_shift in 1..=m {
            let boundary = m as isize - prior_shift as isize - 1;
            for shift in 1..=m {
                if shift < m && pattern[m - shift - 1] as usize != symbol { continue; }
                if (shift as isize) <= boundary &&
                    pattern[(m as isize - shift as isize - prior_shift as isize - 1) as usize] !=
                    pattern[boundary as usize] { continue; }
                bad_character[symbol][prior_shift] = shift as i32;
                break;
            }
        }
    }

    let mut count = 0i64;
    let mut offset_sum = 0i64;
    let mut offset_xor = 0i64;
    let mut start = 0usize;
    let mut shift_state = m;
    let last_start = n - m;
    while start <= last_start {
        while start <= last_start && pattern[m - 1] != text[start + m - 1] {
            shift_state = bad_character[text[start + m - 1] as usize][shift_state] as usize;
            start += shift_state;
        }
        if start > last_start { break; }
        let mut index = 1usize;
        while index < m && pattern[order[index]] == text[start + order[index]] { index += 1; }
        if index == m {
            count += 1;
            offset_sum += start as i64;
            offset_xor ^= start as i64;
        }
        shift_state = good_suffix[index] as usize;
        start += shift_state;
    }
    Ok((count << 36) | (offset_sum << 12) | offset_xor)
}

#[no_mangle]
pub unsafe extern "C" fn reverse_colussi_search(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    execute(std::slice::from_raw_parts(input, length)).unwrap_or(-1)
}
