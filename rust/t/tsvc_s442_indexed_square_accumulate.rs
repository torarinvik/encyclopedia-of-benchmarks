/// Clean-room bounded port of TSVC s442; see package README for provenance.
#[no_mangle]
pub extern "C" fn tsvc_s442_indexed_square_accumulate(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    const MAX_N: usize = 64;
    const MAX_PASSES: usize = 16;
    if input.is_null() || length < 8 || length > 386 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    if values[0] < 1 || values[0] > MAX_N as i64 ||
        values[1] < 1 || values[1] > MAX_PASSES as i64 { return -1; }
    let n = values[0] as usize;
    let passes = values[1] as usize;
    if length != 2 + 6 * n { return -1; }
    let mut a = [0i64; MAX_N];
    let mut b = [0i64; MAX_N];
    let mut c = [0i64; MAX_N];
    let mut d = [0i64; MAX_N];
    let mut e = [0i64; MAX_N];
    let mut selector = [0i64; MAX_N];
    for i in 0..n {
        a[i] = values[2 + i];
        b[i] = values[2 + n + i];
        c[i] = values[2 + 2 * n + i];
        d[i] = values[2 + 3 * n + i];
        e[i] = values[2 + 4 * n + i];
        selector[i] = values[2 + 5 * n + i];
        if !(-2..=2).contains(&a[i]) || !(-2..=2).contains(&b[i]) ||
            !(-2..=2).contains(&c[i]) || !(-2..=2).contains(&d[i]) ||
            !(-2..=2).contains(&e[i]) || !(1..=4).contains(&selector[i]) { return -1; }
    }
    if output.is_null() || capacity < 8 * n { return -2; }
    for _pass in 0..passes {
        for i in 0..n {
            let selected = match selector[i] {
                1 => b[i],
                2 => c[i],
                3 => d[i],
                _ => e[i],
            };
            a[i] += selected * selected;
        }
    }
    let out = unsafe { std::slice::from_raw_parts_mut(output, 8 * n) };
    for i in 0..n {
        out[8 * i..8 * i + 8].copy_from_slice(&a[i].to_le_bytes());
    }
    n as i64
}
