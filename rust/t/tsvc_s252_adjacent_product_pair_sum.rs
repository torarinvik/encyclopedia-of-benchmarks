/// Clean-room bounded port of TSVC s252; see package README for provenance.
#[no_mangle]
pub extern "C" fn tsvc_s252_adjacent_product_pair_sum(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    const MAX_N: usize = 64;
    if input.is_null() || length < 3 || length > 129 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    if values[0] < 1 || values[0] > MAX_N as i64 { return -1; }
    let n = values[0] as usize;
    if length != 1 + 2 * n { return -1; }
    let mut b = [0i64; MAX_N];
    let mut c = [0i64; MAX_N];
    for i in 0..n {
        b[i] = values[1 + i];
        c[i] = values[1 + n + i];
        if !(-2..=2).contains(&b[i]) || !(-2..=2).contains(&c[i]) { return -1; }
    }
    if output.is_null() || capacity < 8 * n { return -2; }
    let out = unsafe { std::slice::from_raw_parts_mut(output, 8 * n) };
    let mut previous_product = 0i64;
    for i in 0..n {
        let product = b[i] * c[i];
        out[8 * i..8 * i + 8].copy_from_slice(&(product + previous_product).to_le_bytes());
        previous_product = product;
    }
    n as i64
}
