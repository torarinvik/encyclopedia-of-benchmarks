/// Return the unique most frequent lowercase ASCII letter as its code point.
#[no_mangle]
pub extern "C" fn max_character(values: *const i64, length: usize) -> i64 {
    if length == 0 || length > 256 || values.is_null() { return -1; }
    let mut counts = [0i64; 26];
    for i in 0..length {
        let value = unsafe { *values.add(i) };
        if !(97..=122).contains(&value) { return -1; }
        counts[(value - 97) as usize] += 1;
    }
    let mut best = 0i64;
    let mut code = -1i64;
    let mut tied = false;
    for (i, count) in counts.iter().enumerate() {
        if *count > best { best = *count; code = 97 + i as i64; tied = false; }
        else if *count == best && best != 0 { tied = true; }
    }
    if tied { -1 } else { code }
}
