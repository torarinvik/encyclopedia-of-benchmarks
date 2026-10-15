const MAX_PATTERNS: usize = 16;
const MAX_PATTERN_LENGTH: usize = 32;
const MAX_TEXT_LENGTH: usize = 256;
const MAX_NODES: usize = 1 + MAX_PATTERNS * MAX_PATTERN_LENGTH;
const ALPHABET: usize = 128;

#[no_mangle]
pub unsafe extern "C" fn aho_corasick(input: *const i64, length: usize, output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length < 3 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(1..=MAX_PATTERNS as i64).contains(&values[0]) || !(0..=MAX_TEXT_LENGTH as i64).contains(&values[1]) { return -1; }
    let pattern_count = values[0] as usize;
    if length < 2 + pattern_count { return -1; }
    let mut starts = [0usize; MAX_PATTERNS];
    let mut text_start = 2 + pattern_count;
    for p in 0..pattern_count {
        if !(1..=MAX_PATTERN_LENGTH as i64).contains(&values[2 + p]) { return -1; }
        let size = values[2 + p] as usize;
        if text_start + size > length { return -1; }
        starts[p] = text_start;
        if values[text_start..text_start + size].iter().any(|&ch| !(1..=127).contains(&ch)) { return -1; }
        for q in 0..p {
            if values[2 + q] as usize == size && values[starts[q]..starts[q] + size] == values[starts[p]..starts[p] + size] { return -1; }
        }
        text_start += size;
    }
    let text_length = values[1] as usize;
    if text_start + text_length != length || values[text_start..].iter().any(|&ch| !(1..=127).contains(&ch)) { return -1; }
    let output_size = pattern_count * 8;
    if output_capacity < output_size || output.is_null() { return -2; }

    let mut next = [[-1i32; ALPHABET]; MAX_NODES];
    let mut failure = [0usize; MAX_NODES];
    let mut terminal = [-1i32; MAX_NODES];
    let mut nodes = 1usize;
    for p in 0..pattern_count {
        let mut state = 0usize;
        for &raw in &values[starts[p]..starts[p] + values[2 + p] as usize] {
            let ch = raw as usize;
            if next[state][ch] == -1 { next[state][ch] = nodes as i32; nodes += 1; }
            state = next[state][ch] as usize;
        }
        terminal[state] = p as i32;
    }
    let mut queue = [0usize; MAX_NODES];
    let (mut head, mut tail) = (0usize, 0usize);
    for ch in 1..ALPHABET { if next[0][ch] != -1 { queue[tail] = next[0][ch] as usize; tail += 1; } }
    while head < tail {
        let state = queue[head]; head += 1;
        for ch in 1..ALPHABET {
            let child = next[state][ch];
            if child == -1 { continue; }
            let mut suffix = failure[state];
            while suffix != 0 && next[suffix][ch] == -1 { suffix = failure[suffix]; }
            if next[suffix][ch] != -1 { suffix = next[suffix][ch] as usize; }
            failure[child as usize] = suffix;
            queue[tail] = child as usize; tail += 1;
        }
    }
    let mut counts = [0i64; MAX_PATTERNS];
    let mut state = 0usize;
    for &raw in &values[text_start..] {
        let ch = raw as usize;
        while state != 0 && next[state][ch] == -1 { state = failure[state]; }
        if next[state][ch] != -1 { state = next[state][ch] as usize; }
        let mut matched = state;
        while matched != 0 {
            if terminal[matched] >= 0 { counts[terminal[matched] as usize] += 1; }
            matched = failure[matched];
        }
    }
    let out = std::slice::from_raw_parts_mut(output, output_size);
    for p in 0..pattern_count { out[p * 8..p * 8 + 8].copy_from_slice(&counts[p].to_le_bytes()); }
    output_size as i64
}
