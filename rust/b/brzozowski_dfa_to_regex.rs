const MAX_STATES: usize = 3;
const MAX_TEXT: usize = 512;
type Text = [u8; MAX_TEXT];

fn text_bytes(text: &Text) -> &[u8] {
    let end = text.iter().position(|byte| *byte == 0).unwrap_or(MAX_TEXT);
    &text[..end]
}

fn text_from(bytes: &[u8]) -> Option<Text> {
    if bytes.len() >= MAX_TEXT { return None; }
    let mut result = [0u8; MAX_TEXT];
    result[..bytes.len()].copy_from_slice(bytes);
    Some(result)
}

fn regex_union(left: &Text, right: &Text) -> Option<Text> {
    let a = text_bytes(left);
    let b = text_bytes(right);
    if a == b"#" { return Some(*right); }
    if b == b"#" || a == b { return Some(*left); }
    let (first, second) = if a < b { (a, b) } else { (b, a) };
    let mut bytes = Vec::with_capacity(first.len() + second.len() + 3);
    bytes.push(b'('); bytes.extend_from_slice(first); bytes.push(b'|');
    bytes.extend_from_slice(second); bytes.push(b')');
    text_from(&bytes)
}

fn regex_concat(left: &Text, right: &Text) -> Option<Text> {
    let a = text_bytes(left);
    let b = text_bytes(right);
    if a == b"#" || b == b"#" { return text_from(b"#"); }
    if a == b"@" { return Some(*right); }
    if b == b"@" { return Some(*left); }
    let mut bytes = Vec::with_capacity(a.len() + b.len() + 3);
    bytes.push(b'('); bytes.extend_from_slice(a); bytes.push(b'.');
    bytes.extend_from_slice(b); bytes.push(b')');
    text_from(&bytes)
}

fn regex_star(value: &Text) -> Option<Text> {
    let inner = text_bytes(value);
    if inner == b"#" || inner == b"@" { return text_from(b"@"); }
    let mut bytes = Vec::with_capacity(inner.len() + 3);
    bytes.push(b'('); bytes.extend_from_slice(inner); bytes.extend_from_slice(b")*");
    text_from(&bytes)
}

#[no_mangle]
pub unsafe extern "C" fn brzozowski_dfa_to_regex(input: *const i64, length: usize,
        output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || !(3..=10).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let (n64, start64, accepting) = (values[0], values[1], values[2]);
    if !(1..=MAX_STATES as i64).contains(&n64) || start64 < 0 || start64 >= n64
        || accepting < 0 || accepting >= (1i64 << n64)
        || length != 3 + 2 * n64 as usize { return -1; }
    let n = n64 as usize;
    let start = start64 as usize;
    let mut coefficient = [[[0u8; MAX_TEXT]; MAX_STATES]; MAX_STATES];
    let mut constant = [[0u8; MAX_TEXT]; MAX_STATES];
    for state in 0..n {
        constant[state] = if accepting & (1i64 << state) != 0 { text_from(b"@").unwrap() }
                          else { text_from(b"#").unwrap() };
        for target in 0..n { coefficient[state][target] = text_from(b"#").unwrap(); }
        for symbol in 0..2 {
            let next = values[3 + 2 * state + symbol];
            if next < 0 || next >= n64 { return -1; }
            let next = next as usize;
            let label = text_from(if symbol == 0 { b"0" } else { b"1" }).unwrap();
            let Some(merged) = regex_union(&coefficient[state][next], &label) else { return -1; };
            coefficient[state][next] = merged;
        }
    }
    for pivot in 0..n {
        if pivot == start { continue; }
        let Some(loop_expr) = regex_star(&coefficient[pivot][pivot]) else { return -1; };
        let pivot_row = coefficient[pivot];
        let pivot_constant = constant[pivot];
        let pivot_column: [Text; MAX_STATES] = std::array::from_fn(|s| coefficient[s][pivot]);
        for source in 0..n {
            if source == pivot { continue; }
            let Some(prefix) = regex_concat(&pivot_column[source], &loop_expr) else { return -1; };
            for target in 0..n {
                if target == pivot { continue; }
                let Some(through) = regex_concat(&prefix, &pivot_row[target]) else { return -1; };
                let Some(merged) = regex_union(&coefficient[source][target], &through) else { return -1; };
                coefficient[source][target] = merged;
            }
            let Some(through) = regex_concat(&prefix, &pivot_constant) else { return -1; };
            let Some(merged) = regex_union(&constant[source], &through) else { return -1; };
            constant[source] = merged;
        }
    }
    let Some(loop_expr) = regex_star(&coefficient[start][start]) else { return -1; };
    let Some(answer) = regex_concat(&loop_expr, &constant[start]) else { return -1; };
    let bytes = text_bytes(&answer);
    if bytes.len() > 270 { return -1; }
    if output.is_null() || capacity < bytes.len() { return -2; }
    std::ptr::copy_nonoverlapping(bytes.as_ptr(), output, bytes.len());
    bytes.len() as i64
}
