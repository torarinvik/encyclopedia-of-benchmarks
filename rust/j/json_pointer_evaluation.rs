const MAX_NODES: usize = 32;
const MAX_POINTER: usize = 64;
const RECORD_WORDS: usize = 21;

unsafe fn field(values: *const i64, base: usize, node: usize, offset: usize) -> i64 {
    *values.add(base + node * RECORD_WORDS + offset)
}

#[no_mangle]
pub unsafe extern "C" fn json_pointer_evaluation(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 3 { return -1; }
    let n_value = *values;
    let root_value = *values.add(1);
    let pointer_value = *values.add(2);
    if n_value < 1 || n_value > MAX_NODES as i64 || root_value < 0 || root_value >= n_value
        || pointer_value < 0 || pointer_value > MAX_POINTER as i64 { return -1; }
    let n = n_value as usize;
    let root = root_value as usize;
    let pointer_length = pointer_value as usize;
    let base = 3 + pointer_length;
    if length != base + n * RECORD_WORDS { return -1; }
    for i in 0..pointer_length {
        let ch = *values.add(3 + i);
        if !(0..=127).contains(&ch) { return -1; }
    }
    if pointer_length != 0 && *values.add(3) != b'/' as i64 { return -1; }
    let mut syntax_pos = 1;
    while syntax_pos < pointer_length {
        if *values.add(3 + syntax_pos) == b'~' as i64 {
            syntax_pos += 1;
            if syntax_pos >= pointer_length { return -1; }
            let escaped = *values.add(3 + syntax_pos);
            if escaped != b'0' as i64 && escaped != b'1' as i64 { return -1; }
        }
        syntax_pos += 1;
    }

    for i in 0..n {
        let kind = field(values, base, i, 0);
        let parent = field(values, base, i, 1);
        let key_length = field(values, base, i, 2);
        let array_index = field(values, base, i, 19);
        if !(0..=2).contains(&kind) || !(0..=16).contains(&key_length) { return -1; }
        if i == root {
            if parent != -1 || key_length != 0 || array_index != -1 { return -1; }
        } else {
            if parent < 0 || parent >= n_value || parent as usize == i { return -1; }
            let parent_kind = field(values, base, parent as usize, 0);
            if parent_kind < 0 || parent_kind > 1 { return -1; }
            if parent_kind == 0 { if array_index != -1 { return -1; } }
            else if key_length != 0 || array_index < 0 { return -1; }
        }
        for k in 0..16 {
            let ch = field(values, base, i, 3 + k);
            if k < key_length as usize {
                if !(0..=127).contains(&ch) { return -1; }
            } else if ch != 0 { return -1; }
        }
        let mut cursor = i;
        let mut hops = 0;
        while cursor != root && hops < n {
            let next = field(values, base, cursor, 1);
            if next < 0 || next >= n_value { return -1; }
            cursor = next as usize;
            hops += 1;
        }
        if cursor != root { return -1; }
    }
    for parent in 0..n {
        if field(values, base, parent, 0) != 1 { continue; }
        let children = (0..n).filter(|&child| field(values, base, child, 1) == parent as i64).count();
        for child in 0..n {
            if field(values, base, child, 1) != parent as i64 { continue; }
            let index = field(values, base, child, 19);
            if index < 0 || index as usize >= children { return -1; }
            for prior in 0..child {
                if field(values, base, prior, 1) == parent as i64
                    && field(values, base, prior, 19) == index { return -1; }
            }
        }
    }

    let mut current = root;
    if pointer_length == 0 { return current as i64; }
    let mut token = [0_i64; MAX_POINTER];
    let mut token_length = 0;
    let mut pos = 1;
    while pos <= pointer_length {
        if pos == pointer_length || *values.add(3 + pos) == b'/' as i64 {
            let kind = field(values, base, current, 0);
            let mut found = n;
            let mut matches = 0;
            if kind == 0 {
                for child in 0..n {
                    if field(values, base, child, 1) != current as i64
                        || field(values, base, child, 2) != token_length as i64 { continue; }
                    let mut k = 0;
                    while k < token_length && field(values, base, child, 3 + k) == token[k] { k += 1; }
                    if k == token_length { found = child; matches += 1; }
                }
            } else if kind == 1 {
                if token_length == 0 || (token_length > 1 && token[0] == b'0' as i64) { return -2; }
                let mut index = 0_i64;
                for &ch in &token[..token_length] {
                    if ch < b'0' as i64 || ch > b'9' as i64 { return -2; }
                    index = index * 10 + ch - b'0' as i64;
                    if index > MAX_NODES as i64 { return -2; }
                }
                for child in 0..n {
                    if field(values, base, child, 1) == current as i64
                        && field(values, base, child, 19) == index { found = child; matches += 1; }
                }
            } else { return -2; }
            if matches != 1 { return -2; }
            current = found;
            token_length = 0;
            pos += 1;
            continue;
        }
        let mut ch = *values.add(3 + pos);
        if ch == b'~' as i64 {
            pos += 1;
            if pos >= pointer_length { return -1; }
            let escaped = *values.add(3 + pos);
            if escaped == b'0' as i64 { ch = b'~' as i64; }
            else if escaped == b'1' as i64 { ch = b'/' as i64; }
            else { return -1; }
        }
        token[token_length] = ch;
        token_length += 1;
        pos += 1;
    }
    current as i64
}
