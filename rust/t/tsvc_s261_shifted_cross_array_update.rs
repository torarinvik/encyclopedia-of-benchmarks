/// Clean-room bounded port of TSVC s261; see package README for provenance.
#[no_mangle]
pub extern "C" fn tsvc_s261_shifted_cross_array_update(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    const MAX_N: usize = 64;
    if input.is_null() || length < 9 || length > 257 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    if values[0] < 2 || values[0] > MAX_N as i64 { return -1; }
    let n = values[0] as usize;
    if length != 1 + 4 * n { return -1; }
    let mut a = [0i64; MAX_N];
    let mut b = [0i64; MAX_N];
    let mut c = [0i64; MAX_N];
    let mut d = [0i64; MAX_N];
    for i in 0..n {
        a[i] = values[1 + i];
        b[i] = values[1 + n + i];
        c[i] = values[1 + 2 * n + i];
        d[i] = values[1 + 3 * n + i];
        if !(-2..=2).contains(&a[i]) || !(-2..=2).contains(&b[i]) ||
            !(-2..=2).contains(&c[i]) || !(-2..=2).contains(&d[i]) { return -1; }
    }
    if output.is_null() || capacity < 16 * n { return -2; }
    for i in 1..n {
        let temporary = a[i] + b[i];
        a[i] = temporary + c[i - 1];
        let product = c[i] * d[i];
        c[i] = product;
    }
    let out = unsafe { std::slice::from_raw_parts_mut(output, 16 * n) };
    for i in 0..n {
        out[8 * i..8 * i + 8].copy_from_slice(&a[i].to_le_bytes());
        out[8 * (n + i)..8 * (n + i) + 8].copy_from_slice(&c[i].to_le_bytes());
    }
    (2 * n) as i64
}
