#[no_mangle]
pub unsafe extern "C" fn reverse_words(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 1 { return -1; }
    let data = std::slice::from_raw_parts(input, length);
    if !(0..=256).contains(&data[0]) || length != data[0] as usize + 1 { return -1; }
    let n = data[0] as usize;
    for i in 0..n {
        let b = data[i + 1];
        if !(b == 32 || (33..=126).contains(&b)) || (b == 32 && (i == 0 || i + 1 == n || data[i] == 32)) { return -1; }
    }
    if output.is_null() || capacity < n + 1 { return -2; }
    let out = std::slice::from_raw_parts_mut(output, capacity);
    let (mut written, mut end) = (0usize, n);
    while end > 0 {
        let mut start = end;
        while start > 0 && data[start] != 32 { start -= 1; }
        let word_start = start;
        for i in word_start..end { out[written] = data[i + 1] as u8; written += 1; }
        if word_start == 0 { break; }
        out[written] = b' '; written += 1; end = start - 1;
    }
    out[written] = 0;
    written as i64
}
