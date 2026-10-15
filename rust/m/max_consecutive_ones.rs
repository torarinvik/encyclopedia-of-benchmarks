/// Return the longest run of ones in a binary array.
#[no_mangle]
pub extern "C" fn max_consecutive_ones(values: *const i64, length: usize) -> i64 {
    if length > 4096 { return -1; }
    if length == 0 { return 0; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    let mut best = 0usize;
    let mut run = 0usize;
    for &value in values {
        if value != 0 && value != 1 { return -1; }
        if value == 1 {
            run += 1;
            if run > best { best = run; }
        } else {
            run = 0;
        }
    }
    best as i64
}
