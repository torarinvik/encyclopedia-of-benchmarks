/// Clean-room port of TSVC s128; see the package README for provenance and rights.
#[no_mangle]
pub extern "C" fn tsvc_s128_strided_coupled_update(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    const MAX_N: usize = 16;
    if input.is_null() || length < 6 || length > 1 + 5 * MAX_N { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    if values[0] < 1 || values[0] > MAX_N as i64 { return -1; }
    let n = values[0] as usize;
    let b_count = 2 * n;
    if length != 1 + 5 * n { return -1; }
    let mut a = [0i64; MAX_N];
    let mut b = [0i64; 2 * MAX_N];
    let mut c = [0i64; 2 * MAX_N];
    let mut d = [0i64; MAX_N];
    for i in 0..b_count {
        b[i] = values[1 + i];
        c[i] = values[1 + b_count + i];
        if !(-100..=100).contains(&b[i]) || !(-100..=100).contains(&c[i]) { return -1; }
    }
    for i in 0..n {
        d[i] = values[1 + 2 * b_count + i];
        if !(-100..=100).contains(&d[i]) { return -1; }
    }
    let output_values = 3 * n;
    let output_bytes = 8 * output_values;
    if output.is_null() || capacity < output_bytes { return -2; }
    let mut j: i64 = -1;
    for i in 0..n {
        let k = (j + 1) as usize;
        a[i] = b[k] - d[i];
        j = k as i64 + 1;
        b[k] = a[i] + c[k];
    }
    let out = unsafe { std::slice::from_raw_parts_mut(output, output_bytes) };
    for (i, &value) in a[..n].iter().chain(b[..b_count].iter()).enumerate() {
        out[8 * i..8 * i + 8].copy_from_slice(&value.to_le_bytes());
    }
    output_values as i64
}
