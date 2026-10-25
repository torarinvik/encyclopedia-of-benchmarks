/// Clean-room port of TSVC s353; see the package README for provenance and rights.
#[no_mangle]
pub extern "C" fn tsvc_s353_unrolled_sparse_saxpy(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    const MAX_N: usize = 20;
    if input.is_null() || length < 17 || length > 2 + 3 * MAX_N { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    if values[0] < 5 || values[0] > MAX_N as i64 || values[0] % 5 != 0 { return -1; }
    let n = values[0] as usize;
    if length != 2 + 3 * n { return -1; }
    let alpha = values[1];
    if !(-8..=8).contains(&alpha) { return -1; }
    let mut a = [0i64; MAX_N];
    let mut b = [0i64; MAX_N];
    let mut indices = [0i64; MAX_N];
    for i in 0..n {
        a[i] = values[2 + i];
        b[i] = values[2 + n + i];
        indices[i] = values[2 + 2 * n + i];
        if !(-1_000_000..=1_000_000).contains(&a[i]) ||
            !(-1_000_000..=1_000_000).contains(&b[i]) ||
            indices[i] < 0 || indices[i] >= n as i64 { return -1; }
    }
    let output_bytes = 8 * n;
    if output.is_null() || capacity < output_bytes { return -2; }
    for i in (0..n).step_by(5) {
        a[i] += alpha * b[indices[i] as usize];
        a[i + 1] += alpha * b[indices[i + 1] as usize];
        a[i + 2] += alpha * b[indices[i + 2] as usize];
        a[i + 3] += alpha * b[indices[i + 3] as usize];
        a[i + 4] += alpha * b[indices[i + 4] as usize];
    }
    let out = unsafe { std::slice::from_raw_parts_mut(output, output_bytes) };
    for (i, &value) in a[..n].iter().enumerate() {
        out[8 * i..8 * i + 8].copy_from_slice(&value.to_le_bytes());
    }
    n as i64
}
