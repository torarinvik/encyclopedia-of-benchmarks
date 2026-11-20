const MAX_TEXT: usize = 32;
const MAX_INPUT: usize = 34;
const MAX_OUTPUT: usize = 512;

fn suffix_less(text: &[i64], mut a: usize, mut b: usize) -> bool {
    while a < text.len() && b < text.len() {
        if text[a] != text[b] { return text[a] < text[b]; }
        a += 1; b += 1;
    }
    a == text.len() && b != text.len()
}

fn lcp(text: &[i64], source: i64, target: usize) -> usize {
    if source < 0 { return 0; }
    let (mut length, mut p) = (0, source as usize);
    while target + length < text.len() && text[p + length] == text[target + length] { length += 1; }
    length
}

fn put64(out: &mut [u8], at: usize, value: i64) {
    let bits = value as u64;
    for i in 0..8 { out[at + i] = (bits >> (8 * i)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn lz77_lpf_suffix_array(input: *const i64, len: usize,
                                                  output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || len < 1 || len > MAX_INPUT { return -1; }
    let n64 = *input;
    if n64 < 0 || n64 > MAX_TEXT as i64 { return -1; }
    let n = n64 as usize;
    if len != n + 1 { return -1; }
    let mut text = [0i64; MAX_TEXT];
    for i in 0..n {
        let value = *input.add(i + 1);
        if !(0..=255).contains(&value) { return -1; }
        text[i] = value;
    }
    let text = &text[..n];
    let mut sa: [usize; MAX_TEXT] = [0; MAX_TEXT];
    let mut inverse: [usize; MAX_TEXT] = [0; MAX_TEXT];
    let mut stack: [usize; MAX_TEXT] = [0; MAX_TEXT];
    let mut previous: [i64; MAX_TEXT] = [-1; MAX_TEXT];
    let mut following: [i64; MAX_TEXT] = [-1; MAX_TEXT];
    for i in 0..n { sa[i] = i; }
    for i in 1..n {
        let value = sa[i];
        let mut j = i;
        while j > 0 && suffix_less(text, value, sa[j - 1]) { sa[j] = sa[j - 1]; j -= 1; }
        sa[j] = value;
    }
    for rank in 0..n { inverse[sa[rank]] = rank; }
    let mut top = 0usize;
    for rank in 0..n {
        while top > 0 && sa[stack[top - 1]] > sa[rank] { top -= 1; }
        if top > 0 { previous[rank] = stack[top - 1] as i64; }
        stack[top] = rank; top += 1;
    }
    top = 0;
    for rr in (0..n).rev() {
        while top > 0 && sa[stack[top - 1]] > sa[rr] { top -= 1; }
        if top > 0 { following[rr] = stack[top - 1] as i64; }
        stack[top] = rr; top += 1;
    }
    let mut staged = [0u8; MAX_OUTPUT];
    let (mut pairs, mut pos) = (0usize, 0usize);
    while pos < n {
        let rank = inverse[pos];
        let psv = if previous[rank] >= 0 { sa[previous[rank] as usize] as i64 } else { -1 };
        let nsv = if following[rank] >= 0 { sa[following[rank] as usize] as i64 } else { -1 };
        let lp = lcp(text, psv, pos);
        let ln = lcp(text, nsv, pos);
        let (mut source, matched) = if ln > lp { (nsv, ln) } else { (psv, lp) };
        if matched == 0 { source = -1; }
        put64(&mut staged, pairs * 16, source);
        put64(&mut staged, pairs * 16 + 8, matched as i64);
        pairs += 1; pos += if matched > 0 { matched } else { 1 };
    }
    let bytes = pairs * 16;
    if output.is_null() || capacity < bytes { return -2; }
    for i in 0..bytes { *output.add(i) = staged[i]; }
    bytes as i64
}
