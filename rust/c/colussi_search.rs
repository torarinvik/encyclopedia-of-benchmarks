const MAX_TEXT_LENGTH: usize = 4096;
const MAX_PATTERN_LENGTH: usize = 128;
const MAX_INPUT_LENGTH: usize = 4227;

fn preprocess(pattern: &[u8; MAX_PATTERN_LENGTH + 1], pattern_length: usize,
              h: &mut [usize; MAX_PATTERN_LENGTH + 1],
              next_table: &mut [usize; MAX_PATTERN_LENGTH + 1],
              shift: &mut [usize; MAX_PATTERN_LENGTH + 1]) -> isize {
    let mut hmax = [0usize; MAX_PATTERN_LENGTH + 2];
    let mut kmin = [0usize; MAX_PATTERN_LENGTH + 1];
    let mut rmin = [0usize; MAX_PATTERN_LENGTH + 1];
    let mut nhd0 = [0usize; MAX_PATTERN_LENGTH + 1];
    let (mut i, mut k) = (1usize, 1usize);
    loop {
        while pattern[i] == pattern[i - k] { i += 1; }
        hmax[k] = i;
        let mut q = k + 1;
        while hmax[q - k] + k < i {
            hmax[q] = hmax[q - k] + k;
            q += 1;
        }
        k = q;
        if k == i + 1 { i = k; }
        if k > pattern_length { break; }
    }

    let mut index = pattern_length;
    while index > 0 {
        if hmax[index] < pattern_length { kmin[hmax[index]] = index; }
        index -= 1;
    }
    let mut r = pattern_length;
    let mut position = pattern_length;
    while position > 0 {
        position -= 1;
        if hmax[position + 1] == pattern_length { r = position + 1; }
        rmin[position] = if kmin[position] == 0 { r } else { 0 };
    }

    let mut nohole_last: isize = -1;
    let mut hole_at = pattern_length;
    for position in 0..pattern_length {
        if kmin[position] == 0 {
            hole_at -= 1;
            h[hole_at] = position;
        } else {
            nohole_last += 1;
            h[nohole_last as usize] = position;
        }
    }
    let nd = nohole_last;
    let mut index = 0usize;
    while (index as isize) <= nd {
        shift[index] = kmin[h[index]];
        index += 1;
    }
    index = (nd + 1) as usize;
    while index < pattern_length {
        shift[index] = rmin[h[index]];
        index += 1;
    }
    shift[pattern_length] = rmin[0];

    let mut nohole_count = 0usize;
    for position in 0..pattern_length {
        nhd0[position] = nohole_count;
        if kmin[position] > 0 { nohole_count += 1; }
    }
    index = 0;
    while (index as isize) <= nd {
        next_table[index] = nhd0[h[index] - kmin[h[index]]];
        index += 1;
    }
    index = (nd + 1) as usize;
    while index < pattern_length {
        next_table[index] = nhd0[pattern_length - rmin[h[index]]];
        index += 1;
    }
    next_table[pattern_length] = nhd0[pattern_length - rmin[h[pattern_length - 1]]];
    nd
}

fn execute(input: &[i64]) -> Result<i64, ()> {
    if input.len() < 2 || input.len() > MAX_INPUT_LENGTH { return Err(()); }
    let (text_length64, pattern_length64) = (input[0], input[1]);
    if text_length64 < 0 || text_length64 > MAX_TEXT_LENGTH as i64
        || pattern_length64 < 1 || pattern_length64 > MAX_PATTERN_LENGTH as i64 { return Err(()); }
    let (text_length, pattern_length) = (text_length64 as usize, pattern_length64 as usize);
    if input.len() != 2 + text_length + pattern_length { return Err(()); }

    let mut text = [0u8; MAX_TEXT_LENGTH];
    let mut pattern = [0u8; MAX_PATTERN_LENGTH + 1];
    for i in 0..text_length {
        let symbol = input[2 + i];
        if !(0..=3).contains(&symbol) { return Err(()); }
        text[i] = symbol as u8;
    }
    let pattern_offset = 2 + text_length;
    for i in 0..pattern_length {
        let symbol = input[pattern_offset + i];
        if !(0..=3).contains(&symbol) { return Err(()); }
        pattern[i] = symbol as u8;
    }
    pattern[pattern_length] = 4;
    if text_length < pattern_length { return Ok(0); }

    let mut h = [0usize; MAX_PATTERN_LENGTH + 1];
    let mut next_table = [0usize; MAX_PATTERN_LENGTH + 1];
    let mut shift = [0usize; MAX_PATTERN_LENGTH + 1];
    let nd = preprocess(&pattern, pattern_length, &mut h, &mut next_table, &mut shift);
    let (mut i, mut j, mut last) = (0usize, 0usize, -1isize);
    let (mut match_count, mut offset_sum, mut offset_xor) = (0i64, 0i64, 0i64);
    while j <= text_length - pattern_length {
        while i < pattern_length && last < (j + h[i]) as isize && pattern[h[i]] == text[j + h[i]] { i += 1; }
        if i >= pattern_length || last >= (j + h[i]) as isize {
            match_count += 1;
            offset_sum += j as i64;
            offset_xor ^= j as i64;
            i = pattern_length;
        }
        if i as isize > nd { last = (j + pattern_length - 1) as isize; }
        j += shift[i];
        i = next_table[i];
    }
    Ok((match_count << 36) | (offset_sum << 12) | offset_xor)
}

#[no_mangle]
pub unsafe extern "C" fn colussi_search(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return -1; }
    execute(std::slice::from_raw_parts(input, length)).unwrap_or(-1)
}
