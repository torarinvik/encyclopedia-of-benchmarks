/// Clean-room port of TSVC s244; see package README for provenance and rights.
#[no_mangle]
pub extern "C" fn tsvc_s244_false_dependence_cycle_break(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    const MAX_N: usize = 32;
    if input.is_null() || length < 9 || length > 129 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    if values[0] < 2 || values[0] > MAX_N as i64 { return -1; }
    let n = values[0] as usize;
    if length != 1 + 4 * n { return -1; }
    let mut a = [0i64; MAX_N];
    let mut b = [0i64; MAX_N];
    let mut c = [0i64; MAX_N];
    let mut d = [0i64; MAX_N];
    let mut trace = [0i64; MAX_N - 1];
    for i in 0..n {
        a[i] = values[1 + i];
        b[i] = values[1 + n + i];
        c[i] = values[1 + 2 * n + i];
        d[i] = values[1 + 3 * n + i];
        if !(-2..=2).contains(&a[i]) || !(-2..=2).contains(&b[i]) ||
            !(-2..=2).contains(&c[i]) || !(-2..=2).contains(&d[i]) { return -1; }
    }
    let output_values = 3 * n - 1;
    if output.is_null() || capacity < 8 * output_values { return -2; }
    for i in 0..n - 1 {
        a[i] = b[i] + c[i] * d[i];
        b[i] = c[i] + b[i];
        a[i + 1] = b[i] + a[i + 1] * d[i];
        trace[i] = a[i + 1];
    }
    let out = unsafe { std::slice::from_raw_parts_mut(output, 8 * output_values) };
    let mut offset = 0;
    for &value in &a[..n] {
        out[8 * offset..8 * offset + 8].copy_from_slice(&value.to_le_bytes());
        offset += 1;
    }
    for &value in &b[..n] {
        out[8 * offset..8 * offset + 8].copy_from_slice(&value.to_le_bytes());
        offset += 1;
    }
    for &value in &trace[..n - 1] {
        out[8 * offset..8 * offset + 8].copy_from_slice(&value.to_le_bytes());
        offset += 1;
    }
    output_values as i64
}
