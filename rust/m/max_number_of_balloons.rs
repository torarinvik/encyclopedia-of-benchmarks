/// Count how many copies of balloon the text can supply.
#[no_mangle]
pub extern "C" fn max_number_of_balloons(text: *const i64, length: usize) -> i64 {
    if length > 256 {
        return -1;
    }
    if length == 0 {
        return 0;
    }
    let text = unsafe { std::slice::from_raw_parts(text, length) };
    let mut b = 0i64;
    let mut a = 0i64;
    let mut l = 0i64;
    let mut o = 0i64;
    let mut n = 0i64;
    for &value in text {
        if !(97..=122).contains(&value) {
            return -1;
        }
        match value {
            98 => b += 1,
            97 => a += 1,
            108 => l += 1,
            111 => o += 1,
            110 => n += 1,
            _ => {}
        }
    }
    [b, a, l / 2, o / 2, n].into_iter().min().unwrap_or(0)
}
