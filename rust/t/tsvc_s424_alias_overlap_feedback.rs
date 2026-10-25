/// Clean-room port of TSVC s424; see package README for provenance and rights.
#[no_mangle]
pub extern "C" fn tsvc_s424_alias_overlap_feedback(input: *const i64, length: usize) -> i64 {
    const MIN_N: usize = 66;
    const MAX_N: usize = 192;
    const X_LENGTH: usize = MAX_N + 63;
    if input.is_null() || length < MIN_N + 64 || length > MAX_N + 64 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    if values[0] < MIN_N as i64 || values[0] > MAX_N as i64 { return -1; }
    let n = values[0] as usize;
    if length != n + 64 { return -1; }
    let mut a = [0i64; MAX_N];
    let mut x = [0i64; X_LENGTH];
    for i in 0..n {
        a[i] = values[1 + i];
        if !(0..=10).contains(&a[i]) { return -1; }
    }
    for i in 0..63 {
        x[i] = values[1 + n + i];
        if !(0..=10).contains(&x[i]) { return -1; }
    }
    // x[63..] is zero-initialized as the source initializes its aliased view.
    for i in 0..n - 1 { x[i + 64] = x[i] + a[i]; }
    x[63..63 + n].iter().sum()
}
