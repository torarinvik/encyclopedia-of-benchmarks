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
    let mut positions = [[0usize; MAX_PATTERN]; 4];
    let mut bucket_size = [0usize; 4];
    for q in 0..m {
        let value = input[2 + n + q];
        if !(0..=3).contains(&value) { return Err(()); }
        pattern[q] = value as u8;
        let symbol = value as usize;
        positions[symbol][bucket_size[symbol]] = q;
        bucket_size[symbol] += 1;
    }

    let (mut count, mut offset_sum, mut offset_xor) = (0i64, 0i64, 0i64);
    let mut sample = m - 1;
    while sample < n {
        let symbol = text[sample] as usize;
        for item in 0..bucket_size[symbol] {
            let pattern_position = positions[symbol][item];
            if sample < pattern_position { continue; }
            let start = sample - pattern_position;
            if start > n - m { continue; }
            let mut matched = 0;
            while matched < m && text[start + matched] == pattern[matched] { matched += 1; }
            if matched == m {
                count += 1;
                offset_sum += start as i64;
                offset_xor ^= start as i64;
            }
        }
        sample += m;
    }
    Ok((count << 36) | (offset_sum << 12) | offset_xor)
}

#[no_mangle]
pub unsafe extern "C" fn skip_search(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    execute(std::slice::from_raw_parts(input, length)).unwrap_or(-1)
}
