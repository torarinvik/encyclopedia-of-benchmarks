const MAX_TEXT: usize = 4096;
const MAX_PATTERN: usize = 128;
const MAX_INPUT: usize = 4227;

fn advance_sample(text: &[u8; MAX_TEXT], n: usize, m: usize,
                  last: &[i32; 4], sample: &mut isize) -> Option<usize> {
    loop {
        *sample += m as isize;
        if *sample >= n as isize { return None; }
        let position = last[text[*sample as usize] as usize];
        if position >= 0 { return Some(position as usize); }
    }
}

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

    let mut mp_next = [0i32; MAX_PATTERN + 1];
    let mut kmp_next = [0i32; MAX_PATTERN + 1];
    let mut q = 0usize;
    let mut border = -1i32;
    mp_next[0] = -1;
    while q < m {
        while border >= 0 && pattern[q] != pattern[border as usize] { border = mp_next[border as usize]; }
        q += 1;
        border += 1;
        mp_next[q] = border;
    }
    q = 0;
    border = -1;
    kmp_next[0] = -1;
    while q < m {
        while border >= 0 && pattern[q] != pattern[border as usize] { border = kmp_next[border as usize]; }
        q += 1;
        border += 1;
        if q < m && pattern[q] == pattern[border as usize] { kmp_next[q] = kmp_next[border as usize]; }
        else { kmp_next[q] = border; }
    }

    let mut last = [-1i32; 4];
    let mut previous = [-1i32; MAX_PATTERN];
    for q in 0..m {
        let symbol = pattern[q] as usize;
        previous[q] = last[symbol];
        last[symbol] = q as i32;
    }

    let mut sample = -1isize;
    let mut i = match advance_sample(&text, n, m, &last, &mut sample) {
        Some(position) => position as i32,
        None => return Ok(0),
    };
    let mut start = sample - i as isize;
    let mut wall = 0isize;
    let period = m as i32 - kmp_next[m];
    let (mut count, mut offset_sum, mut offset_xor) = (0i64, 0i64, 0i64);

    while start <= (n - m) as isize {
        if start > wall { wall = start; }
        let mut k = (wall - start) as usize;
        while k < m && pattern[k] == text[(start as usize) + k] { k += 1; }
        wall = start + k as isize;
        if k == m {
            count += 1;
            offset_sum += start as i64;
            offset_xor ^= start as i64;
            i -= period;
        } else {
            i = previous[i as usize];
        }
        if i < 0 {
            i = match advance_sample(&text, n, m, &last, &mut sample) {
                Some(position) => position as i32,
                None => break,
            };
        }

        let mut kmp_start = start + k as isize - kmp_next[k] as isize;
        let mut k = kmp_next[k];
        start = sample - i as isize;
        while start < kmp_start || (kmp_start < start && start < wall) {
            if start < kmp_start {
                i = previous[i as usize];
                if i < 0 {
                    i = match advance_sample(&text, n, m, &last, &mut sample) {
                        Some(position) => position as i32,
                        None => return Ok((count << 36) | (offset_sum << 12) | offset_xor),
                    };
                }
                start = sample - i as isize;
            } else {
                kmp_start += (k - mp_next[k as usize]) as isize;
                k = mp_next[k as usize];
            }
        }
    }
    Ok((count << 36) | (offset_sum << 12) | offset_xor)
}

#[no_mangle]
pub unsafe extern "C" fn kmp_skip_search(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    execute(std::slice::from_raw_parts(input, length)).unwrap_or(-1)
}
