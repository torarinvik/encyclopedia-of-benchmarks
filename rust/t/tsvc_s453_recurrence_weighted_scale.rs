/// Clean-room port of TSVC s453; see package README for provenance and rights.
#[no_mangle]
pub extern "C" fn tsvc_s453_recurrence_weighted_scale(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    const MAX_N: usize = 32;
    if input.is_null() || length < 2 || length > 33 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    if values[0] < 1 || values[0] > MAX_N as i64 { return -1; }
    let n = values[0] as usize;
    if length != 1 + n { return -1; }
    let mut b = [0i64; MAX_N];
    let mut a = [0i64; MAX_N];
    for i in 0..n {
        b[i] = values[1 + i];
        if !(-100..=100).contains(&b[i]) { return -1; }
    }
    if output.is_null() || capacity < 8 * n { return -2; }
    let mut s: i64 = 0;
    for i in 0..n {
        s += 2;
        a[i] = s * b[i];
    }
    let out = unsafe { std::slice::from_raw_parts_mut(output, 8 * n) };
    for (i, &value) in a[..n].iter().enumerate() {
        out[8 * i..8 * i + 8].copy_from_slice(&value.to_le_bytes());
    }
    n as i64
}
