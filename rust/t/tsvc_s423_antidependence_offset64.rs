#[no_mangle]
pub unsafe extern "C" fn tsvc_s423_antidependence_offset64(input: *const i64, length: usize) -> i64 {
    const MIN_N: usize = 65;
    const MAX_N: usize = 128;
    if input.is_null() || length < MIN_N + 65 || length > MAX_N + 65 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    if values[0] < MIN_N as i64 || values[0] > MAX_N as i64 { return -1; }
    let n = values[0] as usize;
    if length != n + 65 { return -1; }
    let mut a = [0i64; MAX_N];
    let mut x = [0i64; MAX_N + 64];
    for i in 0..n {
        a[i] = values[1+i];
        if !(0..=2).contains(&a[i]) { return -1; }
    }
    for i in 0..64 {
        x[i] = values[1+n+i];
        if !(0..=2).contains(&x[i]) { return -1; }
    }
    for value in &mut x[64..n+64] { *value = 1; }
    for i in 0..n-1 { x[i+1] = x[i+64] + a[i]; }
    x[..n].iter().sum()
}
