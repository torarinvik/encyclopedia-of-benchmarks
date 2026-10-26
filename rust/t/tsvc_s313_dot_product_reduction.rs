const MAX_N: usize = 64;

#[no_mangle]
pub unsafe extern "C" fn tsvc_s313_dot_product_reduction(input: *const f64, length: usize,
    output: *mut f64, capacity: usize) -> i64 {
    if input.is_null() || length < 3 || length > 129 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let rn = values[0];
    if !rn.is_finite() || rn.fract() != 0.0 || rn < 1.0 || rn > MAX_N as f64 { return -1; }
    let n = rn as usize;
    if length != 1 + 2 * n { return -1; }
    if values[1..].iter().any(|x| !x.is_finite() || x.fract() != 0.0 || x.abs() > 1000.0) { return -1; }
    if output.is_null() || capacity < 1 { return -2; }
    let mut sum = 0.0;
    for i in 0..n { sum += values[1 + i] * values[1 + n + i]; }
    unsafe { output.write(sum); }
    1
}
