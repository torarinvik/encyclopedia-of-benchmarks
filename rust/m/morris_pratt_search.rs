const MAX_TEXT: usize = 4096;
const MAX_PATTERN: usize = 128;
const MAX_INPUT: usize = 4227;

fn execute(input: &[i64]) -> Result<i64, ()> {
    if input.len() < 2 || input.len() > MAX_INPUT { return Err(()); }
    let (n64, m64) = (input[0], input[1]);
    if n64 < 0 || n64 > MAX_TEXT as i64 || m64 < 1 || m64 > MAX_PATTERN as i64 { return Err(()); }
    let (n, m) = (n64 as usize, m64 as usize);
    if input.len() != 2 + n + m { return Err(()); }
    let pattern_start = 2 + n;
    if input[2..].iter().any(|&symbol| !(0..=3).contains(&symbol)) { return Err(()); }

    let mut mp_next = [0isize; MAX_PATTERN + 1];
    mp_next[0] = -1;
    for index in 0..m {
        let mut border = mp_next[index];
        while border >= 0 && input[pattern_start + index] != input[pattern_start + border as usize] {
            border = mp_next[border as usize];
        }
        mp_next[index + 1] = border + 1;
    }

    let mut matched = 0isize;
    let (mut count, mut offset_sum, mut offset_xor) = (0i64, 0i64, 0i64);
    for text_index in 0..n {
        while matched >= 0 && input[pattern_start + matched as usize] != input[2 + text_index] {
            matched = mp_next[matched as usize];
        }
        matched += 1;
        if matched as usize == m {
            let start = (text_index + 1 - m) as i64;
            count += 1;
            offset_sum += start;
            offset_xor ^= start;
            matched = mp_next[m];
        }
    }
    Ok((count << 36) | (offset_sum << 12) | offset_xor)
}

#[no_mangle]
pub unsafe extern "C" fn morris_pratt_search(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    execute(std::slice::from_raw_parts(input, length)).unwrap_or(-1)
}
