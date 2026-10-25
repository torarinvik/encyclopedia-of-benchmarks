/// Clean-room port of TSVC s1221; see package README for provenance and rights.
#[no_mangle]
pub extern "C" fn tsvc_s1221_lag4_add_recurrence(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    const MIN_N: usize = 5;
    const MAX_N: usize = 32;
    if input.is_null() || length < 11 || length > 65 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    if values[0] < MIN_N as i64 || values[0] > MAX_N as i64 { return -1; }
    let n = values[0] as usize;
    if length != 1 + 2 * n { return -1; }
    let mut a = [0i64; MAX_N];
    let mut b = [0i64; MAX_N];
    for i in 0..n {
        a[i] = values[1 + i];
        b[i] = values[1 + n + i];
        if !(-10..=10).contains(&a[i]) || !(-10..=10).contains(&b[i]) { return -1; }
    }
    if output.is_null() || capacity < 8 * n { return -2; }
    for i in 4..n { b[i] = b[i - 4] + a[i]; }
    let out = unsafe { std::slice::from_raw_parts_mut(output, 8 * n) };
    for (i, &value) in b[..n].iter().enumerate() {
        out[8 * i..8 * i + 8].copy_from_slice(&value.to_le_bytes());
    }
    n as i64
}
