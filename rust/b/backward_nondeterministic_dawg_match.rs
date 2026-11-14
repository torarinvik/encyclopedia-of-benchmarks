#[no_mangle]
pub unsafe extern "C" fn backward_nondeterministic_dawg_match(
    values: *const i64,
    length: usize,
) -> i64 {
    if values.is_null() || length < 2 || length > 4161 {
        return -2;
    }
    let input = std::slice::from_raw_parts(values, length);
    if !(0..=4096).contains(&input[0]) || !(0..=63).contains(&input[1]) {
        return -2;
    }
    let n = input[0] as usize;
    let m = input[1] as usize;
    if length != 2 + n + m || input[2..].iter().any(|&x| !(97..=122).contains(&x)) {
        return -2;
    }
    if m == 0 { return 0; }
    if m > n { return -1; }

    let mut masks = [0_u64; 26];
    for i in 0..m {
        masks[(input[2 + n + i] - 97) as usize] |= 1_u64 << (m - 1 - i);
    }
    let mut start = 0;
    while start <= n - m {
        let mut remaining = m;
        let mut shift = m;
        let mut states = u64::MAX;
        while remaining > 0 && states != 0 {
            remaining -= 1;
            states &= masks[(input[2 + start + remaining] - 97) as usize];
            if states != 0 {
                if remaining == 0 { return start as i64; }
                shift = remaining;
            }
            states <<= 1;
        }
        start += shift;
    }
    -1
}
