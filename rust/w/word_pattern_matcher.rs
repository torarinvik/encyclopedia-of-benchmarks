fn search(pattern: &[u8], text: &[u8], pi: usize, ti: usize,
          assigned: &mut [Option<Vec<u8>>; 127], used: &mut Vec<Vec<u8>>) -> bool {
    if pi == pattern.len() || ti == text.len() { return pi == pattern.len() && ti == text.len(); }
    let symbol = pattern[pi] as usize;
    if let Some(word) = &assigned[symbol] {
        return text.get(ti..ti + word.len()) == Some(word.as_slice())
            && search(pattern, text, pi + 1, ti + word.len(), assigned, used);
    }
    for end in ti + 1..=text.len() {
        let word = text[ti..end].to_vec();
        if used.contains(&word) { continue; }
        assigned[symbol] = Some(word.clone());
        used.push(word.clone());
        if search(pattern, text, pi + 1, end, assigned, used) { return true; }
        used.pop();
        assigned[symbol] = None;
    }
    false
}

#[no_mangle]
pub unsafe extern "C" fn word_pattern_matcher(input: *const i64, length: usize, _output: *mut u8, _capacity: usize) -> i64 {
    if input.is_null() || length < 2 { return -1; }
    let a = std::slice::from_raw_parts(input, length);
    if !(0..=8).contains(&a[0]) { return -1; }
    let pn = a[0] as usize;
    if length < pn + 2 { return -1; }
    let at = pn + 1;
    if !(0..=32).contains(&a[at]) { return -1; }
    let tn = a[at] as usize;
    if length != at + 1 + tn { return -1; }
    let p = &a[1..at];
    let t = &a[at + 1..];
    if p.iter().chain(t.iter()).any(|&x| !(32..=126).contains(&x)) { return -1; }
    let pattern: Vec<u8> = p.iter().map(|&x| x as u8).collect();
    let text: Vec<u8> = t.iter().map(|&x| x as u8).collect();
    let mut assigned: [Option<Vec<u8>>; 127] = std::array::from_fn(|_| None);
    let mut used = Vec::new();
    search(&pattern, &text, 0, 0, &mut assigned, &mut used) as i64
}
