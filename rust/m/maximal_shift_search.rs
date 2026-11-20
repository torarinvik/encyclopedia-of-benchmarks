const MAX_TEXT: usize = 4096;
const MAX_PATTERN: usize = 128;
const MAX_INPUT: usize = 4227;
const ALPHABET: usize = 4;

fn match_shift(pattern: &[u8; MAX_PATTERN], m: i32, order_loc: &[i32; MAX_PATTERN + 1],
               order_symbol: &[i32; MAX_PATTERN + 1], prefix_length: i32, mut shift: i32) -> i32 {
    while shift < m {
        let mut order_index = prefix_length - 1;
        while order_index >= 0 {
            let pattern_index = order_loc[order_index as usize] - shift;
            if pattern_index >= 0 && order_symbol[order_index as usize] != pattern[pattern_index as usize] as i32 {
                break;
            }
            order_index -= 1;
        }
        if order_index < 0 { break; }
        shift += 1;
    }
    shift
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
        if !(0..ALPHABET as i64).contains(&value) { return Err(()); }
        text[q] = value as u8;
    }
    for q in 0..m {
        let value = input[2 + n + q];
        if !(0..ALPHABET as i64).contains(&value) { return Err(()); }
        pattern[q] = value as u8;
    }
    if n < m { return Ok(0); }

    let mut leading_shift = [0i32; MAX_PATTERN];
    let mut order_loc = [0i32; MAX_PATTERN + 1];
    let mut order_symbol = [0i32; MAX_PATTERN + 1];
    let mut quick_shift = [0i32; ALPHABET];
    let mut adapted_shift = [0i32; MAX_PATTERN + 1];
    for i in 0..m {
        let mut previous = i as i32 - 1;
        while previous >= 0 && pattern[previous as usize] != pattern[i] { previous -= 1; }
        leading_shift[i] = i as i32 - previous;
        let mut position = i;
        while position > 0 {
            let prior_loc = order_loc[position - 1] as usize;
            if leading_shift[prior_loc] > leading_shift[i] ||
                (leading_shift[prior_loc] == leading_shift[i] && prior_loc > i) { break; }
            order_loc[position] = order_loc[position - 1];
            position -= 1;
        }
        order_loc[position] = i as i32;
    }
    for i in 0..m { order_symbol[i] = pattern[order_loc[i] as usize] as i32; }
    order_loc[m] = m as i32;
    order_symbol[m] = -1;
    quick_shift.fill(m as i32 + 1);
    for i in 0..m { quick_shift[pattern[i] as usize] = m as i32 - i as i32; }

    let mut shift = 1i32;
    adapted_shift[0] = 1;
    for prefix_length in 1..=m {
        shift = match_shift(&pattern, m as i32, &order_loc, &order_symbol, prefix_length as i32, shift);
        adapted_shift[prefix_length] = shift;
    }
    for prefix_length in 0..=m {
        shift = adapted_shift[prefix_length];
        while shift < m as i32 {
            let pattern_index = order_loc[prefix_length] - shift;
            if pattern_index < 0 || order_symbol[prefix_length] != pattern[pattern_index as usize] as i32 { break; }
            shift += 1;
            shift = match_shift(&pattern, m as i32, &order_loc, &order_symbol, prefix_length as i32, shift);
        }
        adapted_shift[prefix_length] = shift;
    }

    let mut count = 0i64;
    let mut offset_sum = 0i64;
    let mut offset_xor = 0i64;
    let mut start = 0usize;
    while start <= n - m {
        let mut compared = 0usize;
        while compared < m && order_symbol[compared] == text[start + order_loc[compared] as usize] as i32 {
            compared += 1;
        }
        if compared == m {
            count += 1;
            offset_sum += start as i64;
            offset_xor ^= start as i64;
        }
        let lookahead = start + m;
        if lookahead >= n { break; }
        let advance = adapted_shift[compared].max(quick_shift[text[lookahead] as usize]) as usize;
        start += advance;
    }
    Ok((count << 36) | (offset_sum << 12) | offset_xor)
}

#[no_mangle]
pub unsafe extern "C" fn maximal_shift_search(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    execute(std::slice::from_raw_parts(input, length)).unwrap_or(-1)
}
