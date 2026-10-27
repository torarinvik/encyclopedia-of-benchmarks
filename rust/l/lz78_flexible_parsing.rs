const MAX_TEXT: usize = 32;
const MAX_DICT: usize = MAX_TEXT + 1;
const MAX_INPUT: usize = 34;
const MAX_OUTPUT: usize = 16 * MAX_TEXT;

fn put_u64(output: &mut [u8; MAX_OUTPUT], offset: usize, value: u64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}
fn matches(words: &[[u8; MAX_TEXT]; MAX_DICT], lengths: &[usize; MAX_DICT], id: usize,
           text: &[u8; MAX_TEXT], n: usize, pos: usize) -> bool {
    let len = lengths[id];
    pos + len <= n && words[id][..len] == text[pos..pos + len]
}
fn find_word(words: &[[u8; MAX_TEXT]; MAX_DICT], lengths: &[usize; MAX_DICT], count: usize,
             word: &[u8; MAX_TEXT], len: usize) -> usize {
    for id in 1..count {
        if lengths[id] == len && words[id][..len] == word[..len] { return id; }
    }
    count
}
fn longest(words: &[[u8; MAX_TEXT]; MAX_DICT], lengths: &[usize; MAX_DICT], count: usize,
           extra: &[u8; MAX_TEXT], extra_len: usize, has_extra: bool,
           text: &[u8; MAX_TEXT], n: usize, pos: usize) -> usize {
    let mut best = 0;
    for id in 1..count {
        if lengths[id] > best && matches(words, lengths, id, text, n, pos) { best = lengths[id]; }
    }
    if has_extra && extra_len > best && pos + extra_len <= n && extra[..extra_len] == text[pos..pos + extra_len] {
        best = extra_len;
    }
    best
}

#[no_mangle]
pub unsafe extern "C" fn lz78_flexible_parsing(input: *const i64, length: usize,
                                                 output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if values[0] < 0 || values[0] > MAX_TEXT as i64 { return -1; }
    let n = values[0] as usize;
    if length != n + 1 { return -1; }
    let mut text = [0_u8; MAX_TEXT];
    for i in 0..n {
        if !(32..=126).contains(&values[i + 1]) { return -1; }
        text[i] = values[i + 1] as u8;
    }
    let mut words = [[0_u8; MAX_TEXT]; MAX_DICT];
    let mut lengths = [0_usize; MAX_DICT];
    let mut parents = [0_i64; MAX_TEXT];
    let mut symbols = [0_i64; MAX_TEXT];
    let (mut count, mut token_count, mut pos) = (1_usize, 0_usize, 0_usize);
    while pos < n {
        let mut final_id = count;
        for id in 1..count {
            if lengths[id] == n - pos && words[id][..n - pos] == text[pos..n] { final_id = id; break; }
        }
        if final_id != count {
            parents[token_count] = final_id as i64; symbols[token_count] = 0; token_count += 1; pos = n; break;
        }
        let (mut have, mut best_parent, mut best_len, mut best_next) = (false, 0_usize, 0_usize, 0_usize);
        let mut best_word = [0_u8; MAX_TEXT];
        let (mut best_symbol, mut best_new) = (0_u8, false);
        for parent in 0..count {
            if !matches(&words, &lengths, parent, &text, n, pos) { continue; }
            let prefix_len = lengths[parent];
            let symbol_pos = pos + prefix_len;
            if symbol_pos >= n { continue; }
            let phrase_len = prefix_len + 1;
            let mut phrase = [0_u8; MAX_TEXT];
            phrase[..prefix_len].copy_from_slice(&words[parent][..prefix_len]);
            phrase[prefix_len] = text[symbol_pos];
            let is_new = find_word(&words, &lengths, count, &phrase, phrase_len) == count;
            let next_pos = pos + phrase_len;
            let next_match = longest(&words, &lengths, count, &phrase, phrase_len, is_new, &text, n, next_pos);
            let advancement = phrase_len + next_match;
            if !have || advancement > best_next || (advancement == best_next && phrase_len > best_len) ||
               (advancement == best_next && phrase_len == best_len && parent < best_parent) {
                have = true; best_parent = parent; best_len = phrase_len; best_next = advancement;
                best_word = phrase; best_symbol = text[symbol_pos]; best_new = is_new;
            }
        }
        if !have { return -1; }
        parents[token_count] = best_parent as i64; symbols[token_count] = best_symbol as i64; token_count += 1;
        if best_new { words[count] = best_word; lengths[count] = best_len; count += 1; }
        pos += best_len;
    }
    let bytes = token_count * 16;
    if output.is_null() || capacity < bytes { return -2; }
    let mut staged = [0_u8; MAX_OUTPUT];
    for i in 0..token_count { put_u64(&mut staged, 16 * i, parents[i] as u64); put_u64(&mut staged, 16 * i + 8, symbols[i] as u64); }
    if bytes > 0 { std::ptr::copy_nonoverlapping(staged.as_ptr(), output, bytes); }
    bytes as i64
}
