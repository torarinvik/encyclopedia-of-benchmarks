/// Clean-room port of TSVC s122; see package README for provenance and rights.
#[no_mangle]
pub extern "C" fn tsvc_s122_reverse_strided_gather_add(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    const MAX_N: usize = 32;
    if input.is_null() || length < 5 || length > 67 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    if values[0] < 1 || values[0] > MAX_N as i64 { return -1; }
    let n = values[0] as usize;
    if values[1] < 1 || values[1] > n as i64 || values[2] < 1 || values[2] > n as i64 { return -1; }
    if length != 3 + 2 * n { return -1; }
    let start = values[1] as usize;
    let stride = values[2] as usize;
    let mut a = [0i64; MAX_N];
    let mut b = [0i64; MAX_N];
    for i in 0..n {
        a[i] = values[3 + i];
        b[i] = values[3 + n + i];
        if !(-100..=100).contains(&a[i]) || !(-100..=100).contains(&b[i]) { return -1; }
    }
    if output.is_null() || capacity < 8 * n { return -2; }
    let mut j: usize = 1;
    let mut k: usize = 0;
    let mut i = start - 1;
    while i < n {
        k += j;
        a[i] += b[n - k];
        i += stride;
    }
    let out = unsafe { std::slice::from_raw_parts_mut(output, 8 * n) };
    for (i, &value) in a[..n].iter().enumerate() {
        out[8 * i..8 * i + 8].copy_from_slice(&value.to_le_bytes());
    }
    n as i64
}
