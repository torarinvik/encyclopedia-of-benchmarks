const MAX_TEXT: usize = 16;
const MAX_PARENS: usize = 8;
const MAX_ROWS: usize = 1 << MAX_PARENS;
const MAX_OUTPUT: usize = 4354;

fn balanced(s: &[u8]) -> bool {
    let mut depth = 0i32;
    for &b in s {
        if b == b'(' { depth += 1; }
        else if b == b')' { depth -= 1; if depth < 0 { return false; } }
    }
    depth == 0
}
fn less(a: &[u8], b: &[u8]) -> bool {
    let common = a.len().min(b.len());
    a[..common] < b[..common] || (a[..common] == b[..common] && a.len() < b.len())
}

#[no_mangle]
pub unsafe extern "C" fn minimum_parenthesis_removal_bfs(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 1 || length > MAX_TEXT + 1 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let n64 = values[0];
    if n64 < 0 || n64 > MAX_TEXT as i64 || length != n64 as usize + 1 { return -1; }
    let n = n64 as usize;
    let mut text = [0u8; MAX_TEXT];
    let mut positions = [0usize; MAX_PARENS];
    let mut p = 0usize;
    for i in 0..n {
        let v = values[i + 1];
        if v == 40 || v == 41 {
            if p == MAX_PARENS { return -1; }
            positions[p] = i; p += 1;
        } else if !(97..=122).contains(&v) { return -1; }
        text[i] = v as u8;
    }
    let mut rows = [[0u8; MAX_TEXT]; MAX_ROWS];
    let mut sizes = [0u8; MAX_ROWS];
    let mut count = 0usize;
    let states = 1usize << p;
    for deletions in 0..=p {
        for mask in 0..states {
            if mask.count_ones() as usize != deletions { continue; }
            let mut candidate = [0u8; MAX_TEXT];
            let mut used = 0usize; let mut ordinal = 0usize;
            for i in 0..n {
                let at_paren = ordinal < p && positions[ordinal] == i;
                let remove = at_paren && mask & (1usize << ordinal) != 0;
                if at_paren { ordinal += 1; }
                if !remove { candidate[used] = text[i]; used += 1; }
            }
            if !balanced(&candidate[..used]) { continue; }
            let mut duplicate = false;
            for r in 0..count {
                if sizes[r] as usize == used && rows[r][..used] == candidate[..used] { duplicate = true; break; }
            }
            if !duplicate { rows[count] = candidate; sizes[count] = used as u8; count += 1; }
        }
        if count != 0 { break; }
    }
    if count == 0 { rows[0][0] = 0; sizes[0] = 0; count = 1; }
    for i in 1..count {
        let key = rows[i]; let key_len = sizes[i] as usize; let mut j = i;
        while j > 0 && less(&key[..key_len], &rows[j - 1][..sizes[j - 1] as usize]) {
            rows[j] = rows[j - 1]; sizes[j] = sizes[j - 1]; j -= 1;
        }
        rows[j] = key; sizes[j] = key_len as u8;
    }
    let mut needed = 2usize;
    for r in 0..count { needed += 1 + sizes[r] as usize; }
    if needed > MAX_OUTPUT { return -1; }
    if output.is_null() || capacity < needed { return -2; }
    let out = std::slice::from_raw_parts_mut(output, needed);
    out[0] = count as u8; out[1] = (count >> 8) as u8;
    let mut pos = 2usize;
    for r in 0..count {
        let len = sizes[r] as usize; out[pos] = len as u8; pos += 1;
        out[pos..pos + len].copy_from_slice(&rows[r][..len]); pos += len;
    }
    pos as i64
}
