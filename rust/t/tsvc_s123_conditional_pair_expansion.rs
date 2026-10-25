/// Clean-room port of TSVC s123; see package README for provenance and rights.
#[no_mangle]
pub extern "C" fn tsvc_s123_conditional_pair_expansion(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    const MAX_N: usize = 32;
    if input.is_null() || length < 5 || length > 129 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    if values[0] < 1 || values[0] > MAX_N as i64 { return -1; }
    let n = values[0] as usize;
    if length != 1 + 4 * n { return -1; }
    let mut b = [0i64; MAX_N];
    let mut c = [0i64; MAX_N];
    let mut d = [0i64; MAX_N];
    let mut e = [0i64; MAX_N];
    let mut a = [0i64; 2 * MAX_N];
    for i in 0..n {
        b[i] = values[1 + i];
        c[i] = values[1 + n + i];
        d[i] = values[1 + 2 * n + i];
        e[i] = values[1 + 3 * n + i];
        if !(-100..=100).contains(&b[i]) || !(-100..=100).contains(&c[i]) ||
            !(-100..=100).contains(&d[i]) || !(-100..=100).contains(&e[i]) { return -1; }
    }
    let required_bytes = 16 * n;
    if output.is_null() || capacity < required_bytes { return -2; }
    let mut count = 0;
    for i in 0..n {
        let product = d[i] * e[i];
        a[count] = b[i] + product;
        count += 1;
        if c[i] > 0 {
            a[count] = c[i] + product;
            count += 1;
        }
    }
    let out = unsafe { std::slice::from_raw_parts_mut(output, 8 * count) };
    for (i, &value) in a[..count].iter().enumerate() {
        out[8 * i..8 * i + 8].copy_from_slice(&value.to_le_bytes());
    }
    count as i64
}
