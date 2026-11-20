const MAX_TEXT: usize = 4096;
const MAX_PATTERN: usize = 128;
const MAX_INPUT: usize = 4227;
const MAX_STATES: usize = 2 * MAX_PATTERN + 1;

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

    let mut transitions = [[-1i32; 4]; MAX_STATES];
    let mut suffix_link = [-1i32; MAX_STATES];
    let mut max_length = [0i32; MAX_STATES];
    let mut terminal = [false; MAX_STATES];
    let (mut state_count, mut last) = (1usize, 0usize);
    for pos in 0..m {
        let symbol = pattern[m - 1 - pos] as usize;
        let current = state_count;
        state_count += 1;
        max_length[current] = max_length[last] + 1;
        let mut predecessor = last as i32;
        while predecessor >= 0 && transitions[predecessor as usize][symbol] < 0 {
            transitions[predecessor as usize][symbol] = current as i32;
            predecessor = suffix_link[predecessor as usize];
        }
        if predecessor < 0 {
            suffix_link[current] = 0;
        } else {
            let pred = predecessor as usize;
            let target = transitions[pred][symbol] as usize;
            if max_length[pred] + 1 == max_length[target] {
                suffix_link[current] = target as i32;
            } else {
                let clone = state_count;
                state_count += 1;
                transitions[clone] = transitions[target];
                max_length[clone] = max_length[pred] + 1;
                suffix_link[clone] = suffix_link[target];
                let mut scan = predecessor;
                while scan >= 0 && transitions[scan as usize][symbol] == target as i32 {
                    transitions[scan as usize][symbol] = clone as i32;
                    scan = suffix_link[scan as usize];
                }
                suffix_link[target] = clone as i32;
                suffix_link[current] = clone as i32;
            }
        }
        last = current;
    }
    let mut state = last as i32;
    while state >= 0 {
        terminal[state as usize] = true;
        state = suffix_link[state as usize];
    }

    let mut count = 0i64;
    let mut offset_sum = 0i64;
    let mut offset_xor = 0i64;
    let mut period = m as isize;
    let mut start = 0usize;
    while start <= n - m {
        let mut index = m as isize - 1;
        let mut state = 0usize;
        let mut shift = m as isize;
        while start as isize + index >= 0 {
            let text_index = (start as isize + index) as usize;
            let target = transitions[state][text[text_index] as usize];
            if target < 0 { break; }
            state = target as usize;
            if terminal[state] {
                period = shift;
                shift = index;
            }
            index -= 1;
        }
        if index < 0 {
            count += 1;
            offset_sum += start as i64;
            offset_xor ^= start as i64;
            shift = period;
        }
        start += shift as usize;
    }
    Ok((count << 36) | (offset_sum << 12) | offset_xor)
}

#[no_mangle]
pub unsafe extern "C" fn reverse_factor_search(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    execute(std::slice::from_raw_parts(input, length)).unwrap_or(-1)
}
