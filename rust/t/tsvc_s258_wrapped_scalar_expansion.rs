/// Clean-room port of TSVC s258; see package README for provenance and rights.
#[no_mangle]
pub extern "C" fn tsvc_s258_wrapped_scalar_expansion(input: *const i64, length: usize) -> i64 {
    const MAX_N: usize = 64;
    if input.is_null() || length < 5 || length > 257 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    if values[0] < 1 || values[0] > MAX_N as i64 { return -1; }
    let n = values[0] as usize;
    if length != 1 + 4 * n { return -1; }
    let c_start = 1 + n;
    let d_start = 1 + 2 * n;
    let aa_start = 1 + 3 * n;
    let mut a = [0i64; MAX_N];
    let mut c = [0i64; MAX_N];
    let mut d = [0i64; MAX_N];
    let mut aa0 = [0i64; MAX_N];
    let mut b = [0i64; MAX_N];
    let mut e = [0i64; MAX_N];
    for i in 0..n {
        a[i] = values[1 + i];
        c[i] = values[c_start + i];
        d[i] = values[d_start + i];
        aa0[i] = values[aa_start + i];
        if !(0..=2).contains(&a[i]) || !(0..=2).contains(&c[i]) ||
            !(0..=2).contains(&d[i]) || !(0..=2).contains(&aa0[i]) { return -1; }
    }
    let mut s = 0i64;
    for i in 0..n {
        if a[i] > 0 { s = d[i] * d[i]; }
        b[i] = s * c[i] + d[i];
        e[i] = (s + 1) * aa0[i];
    }
    let mut sum_b = 0i64;
    let mut sum_e = 0i64;
    for i in 0..n {
        sum_b += b[i];
        sum_e += e[i];
    }
    sum_b + sum_e
}
